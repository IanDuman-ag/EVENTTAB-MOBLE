"""Read judge assignments and scores from EventTab admin portal + ORM tables."""

import json
from datetime import date, datetime
from decimal import Decimal

from django.db.models import Max
from django.db import connection
from django.utils import timezone

from .models import Candidate, Criterion, JudgeScore, JudgingEvent

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


def portal_user_id(user):
    """Resolve auth_user.id used by portal assignment tables."""
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM auth_user WHERE username = %s LIMIT 1",
            [user.username],
        )
        row = cursor.fetchone()
    return row[0] if row else user.id


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
    participant_label = "Participants"
    if judging_event_id:
        qs = Candidate.objects.filter(event_id=judging_event_id)
        participant_count = qs.count()
        if participant_count and qs.filter(name__icontains="team").exists():
            participant_label = "Teams"
        elif row.get("num_teams"):
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
        "participant_count": participant_count,
        "participant_label": participant_label,
        "criteria_count": len(criteria),
        "criteria_names": criteria_names,
        "criteria": criteria,
        "total_points": sum(int(c.get("max_score") or 0) for c in criteria) or 100,
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
                    "category": event.category.name if event.category_id else "Event",
                }
            )
        )

    assignments.sort(key=lambda a: (a.get("date") or "", a.get("time_display") or ""))
    return [a for a in assignments if _is_criteria_based_assignment(a)]


def _count_by_status(assignments):
    counts = {"upcoming": 0, "ongoing": 0, "completed": 0}
    for item in assignments:
        status = item.get("status", "upcoming")
        if status in counts:
            counts[status] += 1
    return counts


def fetch_judge_dashboard(user):
    assignments = fetch_judge_assignments(user)
    counts = _count_by_status(assignments)
    today = timezone.localdate()

    todays = [a for a in assignments if a.get("date") == today.isoformat()]
    upcoming = [a for a in assignments if a.get("status") == "upcoming"][:5]

    return {
        "greeting_name": user.username.replace("_", " ").title(),
        "todays_assignments": todays[:5],
        "upcoming_events": upcoming,
        "stats": {
            "assigned": len(assignments),
            "pending": counts["upcoming"] + counts["ongoing"],
            "completed": counts["completed"],
        },
        "counts": counts,
    }


def fetch_assignment_detail(user, judging_event_id):
    assignments = fetch_judge_assignments(user)
    match = next((a for a in assignments if a["judging_event_id"] == judging_event_id), None)

    if match is None:
        try:
            event = JudgingEvent.objects.get(id=judging_event_id)
        except JudgingEvent.DoesNotExist:
            return None
        if not event.assigned_judges.filter(id=user.id).exists():
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
                "category": event.category.name if event.category_id else "Event",
            }
        )

    participants = []
    for candidate in Candidate.objects.filter(event_id=judging_event_id).order_by("number"):
        participants.append(
            {
                "id": candidate.id,
                "number": candidate.number,
                "name": candidate.name,
                "photo": candidate.photo.url if candidate.photo else None,
                "department": getattr(candidate, "department", "") or "",
            }
        )

    legacy_id = portal_user_id(user)
    assigned_at = user.date_joined

    judge_id = f"JDG-{timezone.localdate().year}-{legacy_id:04d}"

    return {
        **match,
        "participants": participants,
        "assignment": {
            "role": "JUDGE",
            "role_detail": f"{match['assignment_type'].title()} Judge",
            "judge_id": judge_id,
            "assigned_at": assigned_at.isoformat() if assigned_at else None,
            "assigned_at_display": _format_date(assigned_at.date()) if assigned_at else "—",
        },
    }


def _weighted_total(scores_qs):
    total = Decimal("0")
    for js in scores_qs:
        if js.criterion.max_score > 0:
            total += js.score * js.criterion.weight_percent / js.criterion.max_score
    return float(round(total, 1))


def _score_review_status(scores_qs):
    if not scores_qs.exists():
        return "pending"
    if scores_qs.filter(is_locked=True).exists():
        return "approved"
    if scores_qs.filter(is_locked=False, submitted_at__isnull=False).exists():
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
        review_status = _score_review_status(scores_qs)
        submitted_at = scores_qs.aggregate(latest=Max("submitted_at"))["latest"]

        if status_filter and status_filter != "all" and review_status != status_filter:
            continue

        event_date = event.date
        if date_from and event_date < date_from:
            continue
        if date_to and event_date > date_to:
            continue

        total = _weighted_total(scores_qs)
        max_score = 100.0
        meta = _category_meta(event.category.name if event.category_id else "Event")

        entries.append(
            {
                "id": f"{event.id}-{candidate.id}",
                "judging_event_id": event.id,
                "candidate_id": candidate.id,
                "category_label": meta["label"],
                "category_icon": meta["icon"],
                "title": event.title,
                "date_display": _format_date(event.date),
                "time_display": _format_time(event.time),
                "venue": event.venue,
                "subject_type": "Team" if "team" in candidate.name.lower() else "Participant",
                "subject_name": f"#{candidate.number} – {candidate.name}",
                "criteria_count": scores_qs.values("criterion_id").distinct().count(),
                "score": total,
                "max_score": max_score,
                "status": review_status,
                "status_label": {
                    "approved": "APPROVED",
                    "pending": "PENDING REVIEW",
                    "rejected": "REJECTED",
                }.get(review_status, review_status.upper()),
                "submitted_at": submitted_at.isoformat() if submitted_at else None,
                "submitted_at_display": (
                    submitted_at.strftime("%b %d, %Y %I:%M %p").lstrip("0")
                    if submitted_at
                    else "—"
                ),
                "processed_by": "Tabulator" if review_status == "approved" else None,
            }
        )

    entries.sort(key=lambda e: e.get("submitted_at") or "", reverse=True)

    counts = {"all": len(entries), "pending": 0, "approved": 0, "rejected": 0}
    for entry in entries:
        key = entry["status"]
        if key in counts:
            counts[key] += 1

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
