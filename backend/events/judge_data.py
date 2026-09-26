"""Read judge assignments and scores from EventTab admin portal + ORM tables."""

import json
import re
from datetime import date, datetime
from decimal import Decimal
from urllib.parse import quote

from django.conf import settings
from django.db.models import Max
from django.db import connection, transaction
from django.utils import timezone

from .models import (
    Candidate,
    CandidateStageEligibility,
    Criterion,
    JudgeScore,
    JudgingEvent,
    JudgingStage,
)

STATUS_MAP = {
    "active": "ongoing",
    "live": "ongoing",
    "in_progress": "ongoing",
    "ongoing": "ongoing",
    "upcoming": "upcoming",
    "scheduled": "upcoming",
    "pending": "upcoming",
    "completed": "completed",
    "finished": "completed",
    "done": "completed",
}

CATEGORY_META = {
    "sports": {"label": "SPORTS", "icon": "sports_soccer"},
    "academic": {"label": "ACADEMIC", "icon": "school"},
    "esports": {"label": "ESPORTS", "icon": "sports_esports"},
    "socio_cultural": {"label": "SOCIO CULTURAL", "icon": "theater_comedy"},
    "socio-cultural": {"label": "SOCIO CULTURAL", "icon": "theater_comedy"},
    "singing": {"label": "SINGING", "icon": "mic"},
    "dance": {"label": "DANCE", "icon": "directions_run"},
    "theater": {"label": "THEATER", "icon": "theater_comedy"},
}


def _absolute_media_url(file_field):
    """Return a media path the Flutter client can prefix with the API host."""
    if not file_field:
        return None
    name = str(getattr(file_field, "name", file_field) or "").strip()
    if name.startswith("cloudinary/"):
        cloud_name = getattr(settings, "CLOUDINARY_CLOUD_NAME", "").strip()
        if not cloud_name:
            return None
        public_id = name.removeprefix("cloudinary/").lstrip("/")
        return (
            f"https://res.cloudinary.com/{cloud_name}/image/upload/"
            f"{quote(public_id, safe='/')}"
        )
    url = file_field.url
    if not url:
        return None
    if url.startswith("http://") or url.startswith("https://"):
        return url
    return url if url.startswith("/") else f"/{url}"


def portal_user_id(user):
    """Resolve auth_user.id used by portal assignment tables."""
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM auth_user WHERE username = %s LIMIT 1",
            [user.username],
        )
        row = cursor.fetchone()
    return row[0] if row else user.id


def user_assigned_to_judging_event(user, judging_event_id):
    """
    True if the judge is assigned via:
    - JudgingEvent.assigned_judges (accounts user / ORM), or
    - events_event_assigned_judges / events_judgingevent_assigned_judges
      (admin portal tables keyed by auth_user.id).
    """
    if user is None or judging_event_id is None:
        return False
    if getattr(user, "is_staff", False) or getattr(user, "is_superuser", False):
        return True
    if JudgingEvent.objects.filter(
        id=judging_event_id, assigned_judges=user
    ).exists():
        return True

    legacy_id = portal_user_id(user)
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT 1
            FROM events_judgingevent_assigned_judges
            WHERE judgingevent_id = %s AND user_id = %s
            LIMIT 1
            """,
            [judging_event_id, legacy_id],
        )
        if cursor.fetchone():
            return True
        cursor.execute(
            """
            SELECT 1
            FROM events_event_assigned_judges ej
            INNER JOIN events_event e ON e.id = ej.event_id
            WHERE e.judging_event_id = %s AND ej.user_id = %s
            LIMIT 1
            """,
            [judging_event_id, legacy_id],
        )
        if cursor.fetchone():
            return True
        # Some portal DBs also store accounts.User.id in M2M tables.
        if legacy_id != user.id:
            cursor.execute(
                """
                SELECT 1
                FROM events_judgingevent_assigned_judges
                WHERE judgingevent_id = %s AND user_id = %s
                LIMIT 1
                """,
                [judging_event_id, user.id],
            )
            if cursor.fetchone():
                return True
            cursor.execute(
                """
                SELECT 1
                FROM events_event_assigned_judges ej
                INNER JOIN events_event e ON e.id = ej.event_id
                WHERE e.judging_event_id = %s AND ej.user_id = %s
                LIMIT 1
                """,
                [judging_event_id, user.id],
            )
            if cursor.fetchone():
                return True
    return False


def _map_status(raw_status):
    return STATUS_MAP.get((raw_status or "upcoming").lower(), "upcoming")


def _category_meta(category_name):
    key = (category_name or "").lower().replace(" ", "_")
    if key in CATEGORY_META:
        return CATEGORY_META[key]
    for token in key.split("_"):
        if token in CATEGORY_META:
            return CATEGORY_META[token]
    return {"label": (category_name or "EVENT").upper(), "icon": "emoji_events"}


def _parse_scoring_criteria(raw):
    """Parse events_event.scoring_criteria JSON into criterion dicts."""
    if not raw:
        return []
    if isinstance(raw, dict):
        data = raw
    else:
        try:
            data = json.loads(raw)
        except (json.JSONDecodeError, TypeError):
            return []

    items = data.get("criteria") if isinstance(data, dict) else None
    if not isinstance(items, list):
        return []

    total_weight = sum(int(c.get("weight") or 0) for c in items) or 100
    parsed = []
    for idx, item in enumerate(items):
        weight = int(item.get("weight") or 0)
        max_score = weight if total_weight == 100 else weight
        parsed.append(
            {
                "id": idx + 1,
                "name": item.get("name") or f"Criterion {idx + 1}",
                "description": item.get("description") or "",
                "max_score": max_score,
                "weight_percent": weight,
                "order": idx,
            }
        )
    return parsed


def _criteria_from_orm(judging_event_id):
    criteria = []
    for c in Criterion.objects.filter(event_id=judging_event_id).order_by("order", "id"):
        name = c.name
        desc = c.description or ""
        if name.startswith("{") and "criteria" in name:
            try:
                blob = json.loads(desc if desc.startswith("{") else name)
                return _parse_scoring_criteria(blob)
            except (json.JSONDecodeError, TypeError):
                pass
        criteria.append(
            {
                "id": c.id,
                "name": name[:80],
                "description": desc[:200],
                "max_score": float(c.max_score),
                "weight_percent": float(c.weight_percent),
                "order": c.order,
            }
        )
    return criteria


def _criteria_for_judging_event(judging_event_id, scoring_criteria_raw=None):
    criteria = _parse_scoring_criteria(scoring_criteria_raw)
    if criteria:
        # Map display criteria to ORM ids when a single bundled row exists.
        orm_rows = list(
            Criterion.objects.filter(event_id=judging_event_id).order_by("order", "id")
        )
        if len(orm_rows) == 1 and len(criteria) > 1:
            bundled = orm_rows[0]
            return [
                {**item, "id": bundled.id, "order": idx}
                for idx, item in enumerate(criteria)
            ]
        if len(orm_rows) == len(criteria):
            return [
                {**criteria[i], "id": orm_rows[i].id}
                for i in range(len(criteria))
            ]
        return criteria

    if judging_event_id:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT e.scoring_criteria
                FROM events_event e
                WHERE e.judging_event_id = %s
                LIMIT 1
                """,
                [judging_event_id],
            )
            row = cursor.fetchone()
            if row and row[0]:
                return _criteria_for_judging_event(judging_event_id, row[0])

    return _criteria_from_orm(judging_event_id)


def _is_placeholder_candidate(candidate):
    """True only for the legacy sample candidate created with a judging event."""
    return bool(re.fullmatch(r"Participant\s+\d+", (candidate.name or "").strip(), re.I))


def _is_placeholder_criterion(criterion):
    """True only for the legacy generic scoring criterion."""
    return (
        (criterion.name or "").strip().lower() == "overall performance"
        and float(criterion.max_score) == 10
    )


def _sync_portal_event_configuration(judging_event_id, portal_event_id):
    """
    Copy the admin portal's selected participants and criteria to Judge data.

    The portal's `participation_type` and `participant_ids` are authoritative:
    individual events sync selected registry candidates; team events sync
    selected teams. Existing scores are never changed.
    """
    if not judging_event_id or not portal_event_id:
        return None

    try:
        event = JudgingEvent.objects.get(id=judging_event_id)
    except JudgingEvent.DoesNotExist:
        return None

    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT participation_type, participant_ids, judging_criteria_config
            FROM events_event
            WHERE id = %s
            """,
            [portal_event_id],
        )
        portal_event = cursor.fetchone()
        if not portal_event:
            return None

        participation_type, participant_ids_raw, criteria_config_raw = portal_event
        participation_type = (participation_type or "individual").lower()
        try:
            participant_ids = (
                participant_ids_raw
                if isinstance(participant_ids_raw, list)
                else json.loads(participant_ids_raw or "[]")
            )
        except (TypeError, json.JSONDecodeError):
            participant_ids = []
        try:
            criteria_config = (
                criteria_config_raw
                if isinstance(criteria_config_raw, list)
                else json.loads(criteria_config_raw or "[]")
            )
        except (TypeError, json.JSONDecodeError):
            criteria_config = []

        if participation_type == "team":
            cursor.execute(
                """
                SELECT t.id, t.name, t.image, d.name
                FROM events_team t
                LEFT JOIN events_department d ON d.id = t.department_id
                WHERE t.status = 'active'
                """
            )
        else:
            cursor.execute(
                """
                SELECT rc.id, rc.name, rc.image, d.name
                FROM events_registrycandidate rc
                LEFT JOIN events_department d ON d.id = rc.department_id
                WHERE rc.status = 'active'
                """
            )
        source_records = {
            str(record_id): (name, image, department)
            for record_id, name, image, department in cursor.fetchall()
        }
        selected_participants = [
            source_records[str(record_id)]
            for record_id in participant_ids
            if str(record_id) in source_records
        ]

    portal_criteria = []
    for item in criteria_config if isinstance(criteria_config, list) else []:
        if not isinstance(item, dict) or not item.get("name"):
            continue
        portal_criteria.append(
            {
                "name": item["name"],
                "description": item.get("description") or "",
                "weight": Decimal(str(item.get("weight") or 0)),
                "max_score": Decimal(str(item.get("max_score") or 100)),
                "order": int(item.get("order") or len(portal_criteria) + 1),
            }
        )

    existing_candidates = list(event.candidates.all().order_by("number", "id"))
    scores_exist = JudgeScore.objects.filter(candidate__event=event).exists()

    with transaction.atomic():
        if selected_participants and not scores_exist:
            by_number = {str(candidate.number): candidate for candidate in existing_candidates}
            for number, (name, image, department) in enumerate(
                selected_participants, start=1
            ):
                candidate = by_number.pop(str(number), None)
                values = {
                    "name": name,
                    "department": department or "",
                    "description": f"Portal {participation_type} for event {portal_event_id}",
                }
                if image:
                    values["photo"] = image
                if candidate:
                    for field, value in values.items():
                        setattr(candidate, field, value)
                    candidate.save(update_fields=[*values.keys()])
                else:
                    Candidate.objects.create(event=event, number=number, **values)

            if by_number:
                Candidate.objects.filter(
                    id__in=[candidate.id for candidate in by_number.values()]
                ).delete()

        if portal_criteria and not scores_exist:
            event.criteria.all().delete()
            for order, criterion in enumerate(portal_criteria):
                Criterion.objects.create(
                    event=event,
                    name=criterion["name"],
                    description=criterion["description"],
                    max_score=criterion["max_score"],
                    weight_percent=criterion["weight"],
                    order=order,
                )
    return participation_type


def _assignment_type(scoring_method, criteria_count):
    method = (scoring_method or "").lower()
    if method == "match":
        return "MATCH BASED"
    if method in ("criteria", "criteria_based", "percentage"):
        return "CRITERIA BASED"
    if criteria_count > 0:
        return "CRITERIA BASED"
    return "MATCH BASED"


def _is_criteria_based_assignment(assignment):
    """Judges only work on criteria-based events, not match/bracket scoring."""
    if assignment.get("assignment_type") != "CRITERIA BASED":
        return False
    return (assignment.get("criteria_count") or 0) > 0


def _format_time(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return value.strftime("%I:%M %p").lstrip("0")


def _format_date(value):
    if value is None:
        return ""
    if isinstance(value, str):
        return value
    return value.strftime("%b %d, %Y")


def _fetch_portal_events_for_user(legacy_user_id):
    sql = """
        SELECT
            e.id AS portal_event_id,
            e.name,
            e.category,
            e.division,
            e.department,
            e.status AS portal_status,
            e.event_date,
            e.event_time,
            e.venue,
            e.scoring_method,
            e.scoring_criteria,
            e.max_participants,
            e.num_teams,
            e.mechanics,
            e.judging_event_id,
            j.title AS judging_title,
            j.status AS judging_status,
            j.description AS judging_description,
            j.date AS judging_date,
            j.time AS judging_time,
            j.venue AS judging_venue,
            j.image_url,
            j.category_id
        FROM events_event e
        INNER JOIN events_event_assigned_judges ej ON ej.event_id = e.id
        LEFT JOIN events_judgingevent j ON j.id = e.judging_event_id
        WHERE ej.user_id = %s
        ORDER BY COALESCE(j.date, e.event_date), COALESCE(j.time, e.event_time)
    """
    with connection.cursor() as cursor:
        cursor.execute(sql, [legacy_user_id])
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _fetch_judging_only_assignments(legacy_user_id):
    sql = """
        SELECT
            j.id AS judging_event_id,
            j.title,
            j.status AS judging_status,
            j.description,
            j.date AS judging_date,
            j.time AS judging_time,
            j.venue AS judging_venue,
            j.image_url,
            j.category_id,
            e.id AS portal_event_id,
            e.name,
            e.category,
            e.division,
            e.department,
            e.status AS portal_status,
            e.event_date,
            e.event_time,
            e.venue AS portal_venue,
            e.scoring_method,
            e.scoring_criteria,
            e.max_participants,
            e.num_teams,
            e.mechanics
        FROM events_judgingevent_assigned_judges ja
        INNER JOIN events_judgingevent j ON j.id = ja.judgingevent_id
        LEFT JOIN events_event e ON e.judging_event_id = j.id
        WHERE ja.user_id = %s
        ORDER BY j.date, j.time
    """
    with connection.cursor() as cursor:
        cursor.execute(sql, [legacy_user_id])
        columns = [col[0] for col in cursor.description]
        return [dict(zip(columns, row)) for row in cursor.fetchall()]


def _serialize_assignment_row(row):
    judging_event_id = row.get("judging_event_id")
    portal_event_id = row.get("portal_event_id")

    participation_type = _sync_portal_event_configuration(
        judging_event_id, portal_event_id
    )

    event_date = row.get("judging_date") or row.get("event_date")
    event_time = row.get("judging_time") or row.get("event_time")
    venue = row.get("judging_venue") or row.get("venue") or row.get("portal_venue") or ""
    title = row.get("judging_title") or row.get("title") or row.get("name") or "Event"
    division = row.get("division") or ""
    category = row.get("category") or "Event"
    portal_status = row.get("portal_status")
    judging_status = row.get("judging_status")
    status = _map_status(judging_status or portal_status)

    criteria = _criteria_for_judging_event(
        judging_event_id,
        row.get("scoring_criteria"),
    )

    participant_count = 0
    participant_label = "Teams" if participation_type == "team" else "Participants"
    if judging_event_id:
        qs = Candidate.objects.filter(event_id=judging_event_id)
        participant_count = qs.count()
        if participation_type is None and row.get("num_teams"):
            participant_count = int(row.get("num_teams") or 0) or participant_count
            participant_label = "Teams"

    criteria_names = [c["name"] for c in criteria]
    assignment_type = _assignment_type(row.get("scoring_method"), len(criteria))
    meta = _category_meta(category)

    subtitle_parts = [p for p in [division] if p]
    subtitle = " – ".join(subtitle_parts) if subtitle_parts else category

    return {
        "id": judging_event_id or portal_event_id,
        "judging_event_id": judging_event_id,
        "portal_event_id": portal_event_id,
        "title": title,
        "subtitle": subtitle,
        "category": category,
        "category_label": meta["label"],
        "category_icon": meta["icon"],
        "assignment_type": assignment_type,
        "scoring_method": (row.get("scoring_method") or "").lower(),
        "status": status,
        "date": event_date.isoformat() if event_date else None,
        "date_display": _format_date(event_date),
        "time_display": _format_time(event_time),
        "venue": venue,
        "image_url": (row.get("image_url") or "").strip(),
        "participant_count": participant_count,
        "participant_label": participant_label,
        "participation_type": participation_type or "individual",
        "criteria_count": len(criteria),
        "criteria_names": criteria_names,
        "criteria": criteria,
        # Criteria can each be scored out of 100, but the final result is the
        # weighted total used by the scoring wizard.
        "total_points": round(
            sum(float(c.get("weight_percent") or 0) for c in criteria)
        ) or 100,
        "description": (row.get("judging_description") or row.get("mechanics") or "").strip(),
    }


def fetch_judge_assignments(user):
    legacy_id = portal_user_id(user)
    seen = set()
    assignments = []

    for row in _fetch_portal_events_for_user(legacy_id):
        key = row.get("judging_event_id") or row.get("portal_event_id")
        if key in seen:
            continue
        seen.add(key)
        assignments.append(_serialize_assignment_row(row))

    for row in _fetch_judging_only_assignments(legacy_id):
        key = row.get("judging_event_id") or row.get("portal_event_id")
        if key in seen:
            continue
        seen.add(key)
        assignments.append(_serialize_assignment_row(row))

    # Django ORM assignments (accounts user)
    for event in JudgingEvent.objects.filter(assigned_judges=user).prefetch_related("candidates"):
        if event.id in seen:
            continue
        seen.add(event.id)
        assignments.append(
            _serialize_assignment_row(
                {
                    "judging_event_id": event.id,
                    "judging_title": event.title,
                    "judging_status": event.status,
                    "judging_description": event.description,
                    "judging_date": event.date,
                    "judging_time": event.time,
                    "judging_venue": event.venue,
                    "image_url": event.image_url,
                    "category": event.category.name if event.category_id else "Event",
                }
            )
        )

    assignments.sort(key=lambda a: (a.get("date") or "", a.get("time_display") or ""))
    criteria_only = [a for a in assignments if _is_criteria_based_assignment(a)]
    # Progress fields are useful on both Home and Events lists.
    return [_enrich_assignment_progress(user, dict(a)) for a in criteria_only]


def _count_by_status(assignments):
    counts = {"all": len(assignments), "upcoming": 0, "ongoing": 0, "completed": 0}
    for item in assignments:
        status = item.get("status", "upcoming")
        if status in counts:
            counts[status] += 1
    return counts


def _candidate_scoring_status(user, candidate):
    scores = JudgeScore.objects.filter(judge=user, candidate=candidate)
    if not scores.exists():
        return "pending", "Pending", ""
    if scores.filter(approval_status="rejected").exists():
        note = scores.filter(approval_status="rejected").exclude(review_note="").values_list(
            "review_note", flat=True
        ).first() or ""
        return "returned", "Returned for Correction", note
    if scores.filter(is_locked=True, is_draft=False).exists():
        return "submitted", "Submitted", ""
    if scores.filter(is_draft=True).exists() or scores.filter(is_locked=False).exists():
        return "draft", "Draft Saved", ""
    return "pending", "Pending", ""


def _event_display_status(assignment):
    """Map internal status to judge-facing status labels."""
    raw = (assignment.get("status") or "upcoming").lower()
    if raw == "completed":
        return "Completed"
    if raw == "upcoming":
        return "Upcoming"
    # ongoing / active
    progress = assignment.get("scoring_progress") or 0
    if progress <= 0:
        return "Scoring Open"
    if progress >= 100:
        return "Waiting for Next Stage"
    return "Ongoing"


def _active_stage_payload(event):
    stages = list(event.stages.all().order_by("order", "id"))
    if not stages:
        return {
            "id": None,
            "name": "Main Scoring",
            "description": event.description or "Single-stage criteria scoring",
            "weight_percent": 100,
            "order": 0,
            "status": "scoring_open" if event.status == "active" else (
                "completed" if event.status == "completed" else "upcoming"
            ),
            "qualifier_count": event.candidates.count(),
            "scoring_deadline": None,
            "is_active": event.status == "active",
        }, []
    active = next((s for s in stages if s.is_active), stages[0])
    payload = {
        "id": active.id,
        "name": active.name,
        "description": active.description,
        "weight_percent": float(active.weight_percent),
        "order": active.order,
        "status": active.status,
        "qualifier_count": active.qualifier_count,
        "scoring_deadline": active.scoring_deadline.isoformat() if active.scoring_deadline else None,
        "is_active": active.is_active,
    }
    all_stages = [
        {
            "id": s.id,
            "name": s.name,
            "description": s.description,
            "weight_percent": float(s.weight_percent),
            "order": s.order,
            "status": s.status,
            "qualifier_count": s.qualifier_count,
            "scoring_deadline": s.scoring_deadline.isoformat() if s.scoring_deadline else None,
            "is_active": s.is_active,
        }
        for s in stages
    ]
    return payload, all_stages


def _enrich_assignment_progress(user, item):
    """Attach scoring progress / current round for dashboard cards."""
    jid = item.get("judging_event_id")
    if not jid:
        return item

    total = Candidate.objects.filter(event_id=jid).count() or 0
    scored = (
        JudgeScore.objects.filter(
            judge=user, candidate__event_id=jid, is_locked=True, is_draft=False
        )
        .values("candidate_id")
        .distinct()
        .count()
    )
    item["contestants_total"] = total
    item["participants_total"] = total
    item["contestants_scored"] = scored
    item["participants_scored"] = scored
    item["scoring_progress"] = int(round((scored / total) * 100)) if total else 0
    item["event_status_label"] = _event_display_status(
        {**item, "scoring_progress": item["scoring_progress"]}
    )
    item["current_stage"] = "Main Scoring"
    item["current_round"] = "Main Scoring"
    item["rounds_count"] = 1
    item["judge_mode"] = "Scoring"
    try:
        ev = JudgingEvent.objects.get(id=jid)
        active, all_stages = _active_stage_payload(ev)
        item["current_stage"] = active["name"]
        item["current_round"] = active["name"]
        item["rounds_count"] = max(len(all_stages), 1)
        item["faculty_in_charge"] = ev.faculty_in_charge or ""
        item["judges_count"] = ev.assigned_judges.count()
    except JudgingEvent.DoesNotExist:
        item["judges_count"] = 0

    # Action label for mobile CTAs
    status = item.get("status")
    if status == "ongoing":
        item["action_label"] = (
            "Continue Judging" if scored > 0 else "Open Event"
        )
    elif status == "completed":
        item["action_label"] = "View Submission"
    else:
        item["action_label"] = "View Event"
    return item


def fetch_judge_dashboard(user):
    assignments = fetch_judge_assignments(user)
    counts = _count_by_status(assignments)
    today = timezone.localdate()

    # Enrich every assigned event so Home can render progress cards.
    assigned_events = [_enrich_assignment_progress(user, dict(a)) for a in assignments]
    # Ongoing first, then upcoming, then completed; nearest date first within group.
    status_rank = {"ongoing": 0, "upcoming": 1, "completed": 2}
    assigned_events.sort(
        key=lambda a: (
            status_rank.get(a.get("status"), 9),
            a.get("date") or "",
            a.get("time_display") or "",
        )
    )

    todays = [a for a in assigned_events if a.get("date") == today.isoformat()]
    upcoming = [a for a in assigned_events if a.get("status") == "upcoming"][:5]
    ongoing = [a for a in assigned_events if a.get("status") == "ongoing"]

    # Participant-level stats across assigned events
    event_ids = [a["judging_event_id"] for a in assignments if a.get("judging_event_id")]
    candidates = Candidate.objects.filter(event_id__in=event_ids)
    pending_participants = 0
    draft_scores = 0
    submitted_scores = 0
    for cand in candidates:
        status_key, _, _ = _candidate_scoring_status(user, cand)
        if status_key == "pending":
            pending_participants += 1
        elif status_key == "draft":
            draft_scores += 1
        elif status_key in ("submitted", "returned"):
            if status_key == "submitted":
                submitted_scores += 1
            else:
                pending_participants += 1  # returned counts as needing action

    return {
        "greeting_name": user.get_full_name() or user.username.replace("_", " ").title(),
        "dashboard_title": "Judge Dashboard",
        "assigned_events": assigned_events,
        "todays_assignments": todays[:5],
        "ongoing_events": ongoing,
        "upcoming_events": upcoming,
        "stats": {
            "assigned": len(assignments),
            "pending": pending_participants,
            "draft": draft_scores,
            "submitted": submitted_scores,
            # legacy keys for older clients
            "completed": submitted_scores,
        },
        "counts": counts,
        "last_submission": _latest_judge_submission(user),
    }


def fetch_assignment_detail(user, judging_event_id):
    assignments = fetch_judge_assignments(user)
    match = next((a for a in assignments if a["judging_event_id"] == judging_event_id), None)

    if match is None:
        try:
            event = JudgingEvent.objects.get(id=judging_event_id)
        except JudgingEvent.DoesNotExist:
            return None
        if not user_assigned_to_judging_event(user, judging_event_id):
            scored = JudgeScore.objects.filter(
                judge=user, candidate__event_id=judging_event_id
            ).exists()
            if not scored:
                return None
        match = _serialize_assignment_row(
            {
                "judging_event_id": event.id,
                "judging_title": event.title,
                "judging_status": event.status,
                "judging_description": event.description,
                "judging_date": event.date,
                "judging_time": event.time,
                "judging_venue": event.venue,
                "image_url": event.image_url,
                "category": event.category.name if event.category_id else "Event",
            }
        )

    try:
        event = JudgingEvent.objects.get(id=judging_event_id)
    except JudgingEvent.DoesNotExist:
        return None

    active_stage, all_stages = _active_stage_payload(event)
    qualified_ids = None
    if active_stage.get("id"):
        elig = list(
            CandidateStageEligibility.objects.filter(
                stage_id=active_stage["id"]
            ).values_list("candidate_id", "is_qualified")
        )
        if elig:
            qualified_ids = {cid for cid, ok in elig if ok}

    participants = []
    scored_count = 0
    remaining = 0
    for candidate in Candidate.objects.filter(event_id=judging_event_id).order_by("number"):
        is_qualified = True
        if qualified_ids is not None and candidate.id not in qualified_ids:
            is_qualified = False
        status_key, status_label, review_note = _candidate_scoring_status(user, candidate)
        if not is_qualified:
            status_key, status_label = "not_qualified", "Not Qualified"
        if status_key == "submitted":
            scored_count += 1
        elif is_qualified:
            remaining += 1

        action = {
            "pending": "Score",
            "draft": "Continue",
            "submitted": "View Submission",
            "returned": "Edit Score",
            "not_qualified": "Not Qualified",
        }.get(status_key, "Score")

        draft_step = (
            JudgeScore.objects.filter(judge=user, candidate=candidate, is_draft=True)
            .values_list("draft_step", flat=True)
            .first()
            or 0
        )

        if is_qualified or status_key == "not_qualified":
            # Only include not_qualified when listing all; active scoring list filters them out client-side
            pass

        participants.append(
            {
                "id": candidate.id,
                "number": candidate.number,
                "name": candidate.name,
                "photo": _absolute_media_url(candidate.photo),
                "department": candidate.department or candidate.description or "",
                "scoring_status": status_key,
                "scoring_status_label": status_label,
                "review_note": review_note,
                "action_label": action,
                "is_qualified": is_qualified,
                "draft_step": draft_step,
            }
        )

    total = len([p for p in participants if p["is_qualified"]])
    scored_count = len([p for p in participants if p["scoring_status"] == "submitted" and p["is_qualified"]])
    remaining = total - scored_count
    progress = int(round((scored_count / total) * 100)) if total else 0

    # Prefer ORM criteria with scoring metadata
    criteria = _criteria_for_judging_event(judging_event_id, None)
    orm_criteria = Criterion.objects.filter(event_id=judging_event_id).order_by("order", "id")
    if orm_criteria.exists():
        criteria = []
        for c in orm_criteria:
            if active_stage.get("id") and c.stage_id and c.stage_id != active_stage["id"]:
                continue
            criteria.append(
                {
                    "id": c.id,
                    "name": c.name,
                    "description": c.description or "",
                    "max_score": float(c.max_score),
                    "min_score": float(c.min_score or 0),
                    "weight_percent": float(c.weight_percent),
                    "order": c.order,
                    "comment_enabled": c.comment_enabled,
                    "comment_required": c.comment_required,
                    "low_score_comment_threshold": (
                        float(c.low_score_comment_threshold)
                        if c.low_score_comment_threshold is not None
                        else None
                    ),
                    "decimal_places": c.decimal_places,
                }
            )

    legacy_id = portal_user_id(user)
    assigned_at = user.date_joined
    judge_id = f"JDG-{timezone.localdate().year}-{legacy_id:04d}"

    event_action = {
        "upcoming": "Open Event",
        "ongoing": "Continue Scoring" if scored_count < total else "Waiting for Next Stage",
        "completed": "View Submission",
    }.get(match.get("status"), "Open Event")
    if match.get("status") == "ongoing" and scored_count == 0:
        event_action = "Open Event"

    return {
        **match,
        "instructions": event.instructions or event.description or "",
        "faculty_in_charge": event.faculty_in_charge or "",
        "event_classification": match.get("assignment_type") or "CRITERIA BASED",
        "current_stage": active_stage,
        "stages": all_stages,
        "event_status_label": _event_display_status({**match, "scoring_progress": progress}),
        "scoring_status": f"{scored_count}/{total} scored",
        "contestants_total": total,
        "contestants_scored": scored_count,
        "contestants_remaining": remaining,
        "scoring_progress": progress,
        "action_label": event_action,
        "criteria": criteria if criteria else match.get("criteria") or [],
        "participants": participants,
        "assignment": {
            "role": "JUDGE",
            "role_detail": f"{match['assignment_type'].title()} Judge",
            "judge_id": judge_id,
            "assigned_at": assigned_at.isoformat() if assigned_at else None,
            "assigned_at_display": _format_date(assigned_at.date()) if assigned_at else "—",
        },
    }


def _latest_judge_submission(user):
    latest = (
        JudgeScore.objects.filter(judge=user, is_locked=True, is_draft=False)
        .exclude(submitted_at__isnull=True)
        .select_related("candidate", "candidate__event")
        .order_by("-submitted_at")
        .first()
    )
    if latest is None:
        return None
    submitted_at = latest.submitted_at
    return {
        "candidate_id": latest.candidate_id,
        "candidate_name": latest.candidate.name,
        "judging_event_id": latest.candidate.event_id,
        "event_title": latest.candidate.event.title,
        "submitted_at": submitted_at.isoformat() if submitted_at else None,
        "submitted_at_display": (
            submitted_at.strftime("%b %d, %Y %I:%M %p").lstrip("0")
            if submitted_at
            else "Just now"
        ),
        "message": "Last submission saved successfully.",
        "verification_id": latest.verification_id or "",
    }


def _entry_scoring_status(scores_qs):
    if scores_qs.filter(approval_status="rejected").exists():
        return "returned", "Returned"
    if scores_qs.filter(is_locked=True, is_draft=False).exists():
        return "submitted", "Submitted"
    if scores_qs.filter(is_draft=True).exists() or scores_qs.filter(is_locked=False).exists():
        return "draft", "Draft"
    return "pending", "Pending"


def _weighted_total(scores_qs):
    total = Decimal("0")
    for js in scores_qs:
        if js.criterion.max_score > 0:
            total += js.score * js.criterion.weight_percent / js.criterion.max_score
    return float(round(total, 1))


def _score_review_status(scores_qs):
    if not scores_qs.exists():
        return "pending"
    statuses = list(scores_qs.values_list("approval_status", flat=True))
    if any(s == "rejected" for s in statuses):
        return "rejected"
    if statuses and all(s == "approved" for s in statuses):
        return "approved"
    if any(s == "pending" for s in statuses) or scores_qs.filter(
        submitted_at__isnull=False
    ).exists():
        return "pending"
    return "pending"


def fetch_score_history(user, status_filter=None, date_from=None, date_to=None):
    candidates_scored = (
        JudgeScore.objects.filter(judge=user)
        .values_list("candidate_id", flat=True)
        .distinct()
    )

    entries = []
    for candidate_id in candidates_scored:
        scores_qs = JudgeScore.objects.filter(
            judge=user, candidate_id=candidate_id
        ).select_related("candidate", "candidate__event", "criterion")
        if not scores_qs.exists():
            continue

        sample = scores_qs.first()
        candidate = sample.candidate
        event = candidate.event
        scoring_status, scoring_label = _entry_scoring_status(scores_qs)
        review_status = _score_review_status(scores_qs)
        submitted_at = scores_qs.aggregate(latest=Max("submitted_at"))["latest"]

        allowed = {"all", "", None}
        if status_filter not in allowed:
            if status_filter in ("draft", "submitted", "returned", "pending"):
                if scoring_status != status_filter:
                    continue
            elif review_status != status_filter:
                continue

        event_date = event.date
        if date_from and event_date < date_from:
            continue
        if date_to and event_date > date_to:
            continue

        criteria_count = scores_qs.values("criterion_id").distinct().count()
        # Judges only see criteria-based results (not match/score-only events).
        if criteria_count <= 0:
            continue
        scoring_method = (
            getattr(event, "scoring_method", None)
            or getattr(event, "scoring_type", None)
            or ""
        )
        if str(scoring_method).lower() in ("match", "score", "score_based", "bracket"):
            continue

        total = _weighted_total(scores_qs)
        max_score = 100.0
        meta = _category_meta(event.category.name if event.category_id else "Event")
        verification_id = (
            scores_qs.exclude(verification_id="").values_list("verification_id", flat=True).first()
            or ""
        )
        current_round = "Main Scoring"
        try:
            active, _ = _active_stage_payload(event)
            current_round = active.get("name") or "Main Scoring"
        except Exception:
            pass

        stamp = submitted_at
        entries.append(
            {
                "id": f"{event.id}-{candidate.id}",
                "judging_event_id": event.id,
                "candidate_id": candidate.id,
                "candidate_number": candidate.number,
                "candidate_name": candidate.name,
                "department": candidate.department or candidate.description or "",
                "photo": _absolute_media_url(candidate.photo),
                "category_label": meta["label"],
                "category_icon": meta["icon"],
                "title": event.title,
                "current_round": current_round,
                "date_display": _format_date(event.date),
                "time_display": _format_time(event.time),
                "venue": event.venue,
                "subject_type": "Team" if "team" in candidate.name.lower() else "Participant",
                "subject_name": f"#{candidate.number} – {candidate.name}",
                "criteria_count": criteria_count,
                "score": total,
                "max_score": max_score,
                "scoring_status": scoring_status,
                "status": scoring_status,
                "status_label": scoring_label,
                "review_status": review_status,
                "verification_id": verification_id,
                "submitted_at": submitted_at.isoformat() if submitted_at else None,
                "submitted_at_display": (
                    stamp.strftime("%b %d, %Y %I:%M %p").lstrip("0")
                    if stamp
                    else "—"
                ),
            }
        )

    entries.sort(key=lambda e: e.get("submitted_at") or "", reverse=True)

    counts = {
        "all": 0,
        "draft": 0,
        "submitted": 0,
        "returned": 0,
        "pending": 0,
        "approved": 0,
        "rejected": 0,
    }
    for entry in entries:
        counts["all"] += 1
        key = entry.get("scoring_status")
        if key in counts:
            counts[key] += 1
        review = entry.get("review_status")
        if review in counts:
            counts[review] += 1

    return {"entries": entries, "counts": counts}


def fetch_judge_profile(user):
    assignments = fetch_judge_assignments(user)
    legacy_id = portal_user_id(user)

    completed_candidates = (
        JudgeScore.objects.filter(judge=user, is_locked=True)
        .values("candidate_id")
        .distinct()
        .count()
    )
    pending_candidates = (
        JudgeScore.objects.filter(judge=user, is_locked=False)
        .values("candidate_id")
        .distinct()
        .count()
    )

    month_start = date.today().replace(day=1)
    events_this_month = sum(
        1
        for a in assignments
        if a.get("date") and a["date"] >= month_start.isoformat()
    )

    judge_id = f"JDG-{timezone.localdate().year}-{legacy_id:04d}"
    display_name = user.username.replace("_", " ").replace(".", " ").title()

    return {
        "display_name": display_name,
        "username": user.username,
        "email": user.email or "",
        "judge_id": judge_id,
        "role": "JUDGE",
        "role_detail": "Criteria-Based Judge",
        "status": "ACTIVE" if user.is_active else "INACTIVE",
        "member_since": user.date_joined.date().isoformat() if user.date_joined else None,
        "member_since_display": _format_date(user.date_joined.date()) if user.date_joined else "—",
        "stats": {
            "assignments": len(assignments),
            "completed": completed_candidates,
            "pending": pending_candidates,
            "events_this_month": events_this_month,
        },
    }


def fetch_notification_count(user):
    unread = 0
    for event in JudgingEvent.objects.filter(assigned_judges=user, status="active"):
        unread += 1
    legacy_id = portal_user_id(user)
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT COUNT(*)
            FROM events_event_assigned_judges ej
            INNER JOIN events_event e ON e.id = ej.event_id
            WHERE ej.user_id = %s AND e.status = 'active'
            """,
            [legacy_id],
        )
        unread += cursor.fetchone()[0]
    return unread
