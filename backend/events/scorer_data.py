"""Read scorer assignments and bracket matches from EventTab admin portal tables."""

from datetime import date

from django.db import connection
from django.utils import timezone

from .bracket_data import fetch_bracket_matches, serialize_bracket_row
from .models import BracketScorerSubmission, ScorerSubmission

SPORT_ICONS = {
    "basketball": "sports_basketball",
    "volleyball": "sports_volleyball",
    "football": "sports_soccer",
    "table tennis": "sports_tennis",
    "tennis": "sports_tennis",
    "esports": "sports_esports",
}


def portal_user_id(user):
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT id FROM auth_user WHERE username = %s LIMIT 1",
            [user.username],
        )
        row = cursor.fetchone()
    return row[0] if row else user.id


def _table_exists(table_name):
    with connection.cursor() as cursor:
        cursor.execute("SELECT to_regclass(%s)", [f"public.{table_name}"])
        row = cursor.fetchone()
    return row and row[0] is not None


def fetch_scorer_assigned_event_ids(user):
    """Event IDs this scorer is assigned to work on (match/bracket events only)."""
    legacy_id = portal_user_id(user)

    if _table_exists("events_event_assigned_scorers"):
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT event_id
                FROM events_event_assigned_scorers
                WHERE user_id = %s
                """,
                [legacy_id],
            )
            ids = [row[0] for row in cursor.fetchall()]
            if ids:
                return ids

    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT DISTINCT e.id
            FROM events_event e
            INNER JOIN events_bracketmatch bm ON bm.event_id = e.id
            WHERE e.status = 'active'
              AND LOWER(COALESCE(e.scoring_method, '')) = 'match'
            ORDER BY e.id
            """
        )
        return [row[0] for row in cursor.fetchall()]


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


def _sport_key(event_name, category):
    text = f"{event_name or ''} {category or ''}".lower()
    for key in SPORT_ICONS:
        if key in text:
            return key.replace(" ", "_")
    return (category or "sports").lower().replace(" ", "_")


def _sport_icon(event_name, category):
    return SPORT_ICONS.get(
        _sport_key(event_name, category).replace("_", " "),
        SPORT_ICONS.get(_sport_key(event_name, category), "sports"),
    )


def _enrich_match(match, event_name=None, category=None):
    """Add display fields used by the scorer portal UI."""
    team_a = match.get("team_a") or {}
    team_b = match.get("team_b") or {}
    round_display = match.get("round_label_display") or "Match"
    event_label = event_name or match.get("event_name") or "Event"

    scheduled = match.get("scheduled_time") or ""
    match_date = None
    match_time = None
    if scheduled and "T" in scheduled:
        date_part, time_part = scheduled.split("T", 1)
        match_date = date_part
        match_time = time_part[:5]

    status = match.get("status") or "upcoming"
    score_a = match.get("score_a")
    score_b = match.get("score_b")
    has_scores = score_a is not None or score_b is not None

    return {
        **match,
        "event_name": event_label,
        "match_title": f"{event_label} — {round_display}",
        "sport_icon": _sport_icon(event_label, category or match.get("sport")),
        "date_display": _format_date(match_date) if match_date else "",
        "time_display": _format_time(match_time) if match_time else "",
        "date": match_date,
        "teams_label": f"{team_a.get('name', 'TBD')} vs {team_b.get('name', 'TBD')}",
        "has_started_scoring": has_scores or status == "live",
        "is_score_locked": status == "completed",
        "action_label": "CONTINUE SCORING"
        if has_scores or status == "live"
        else "START SCORING",
    }


def fetch_scorer_matches(user, event_ids=None):
    if event_ids is None:
        event_ids = fetch_scorer_assigned_event_ids(user)
    if not event_ids:
        return []

    event_ids_set = set(event_ids)
    matches = fetch_bracket_matches()
    enriched = []

    event_meta = {}
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT id, name, category, venue, event_date, event_time
            FROM events_event
            WHERE id = ANY(%s)
            """,
            [list(event_ids_set)],
        )
        for row in cursor.fetchall():
            event_meta[row[0]] = {
                "name": row[1],
                "category": row[2],
                "venue": row[3],
                "event_date": row[4],
                "event_time": row[5],
            }

    for match in matches:
        if match.get("event_id") not in event_ids_set:
            continue
        meta = event_meta.get(match["event_id"], {})
        if not match.get("venue"):
            match["venue"] = meta.get("venue") or ""
        if not match.get("scheduled_time") and meta.get("event_date"):
            event_time = meta.get("event_time")
            time_str = event_time.isoformat() if event_time else "00:00:00"
            match["scheduled_time"] = f"{meta['event_date']}T{time_str}"
        enriched.append(
            _enrich_match(match, meta.get("name"), meta.get("category"))
        )

    return enriched


def _split_matches(matches):
    live = [m for m in matches if m["status"] == "live"]
    upcoming = [m for m in matches if m["status"] == "upcoming"]
    completed = [m for m in matches if m["status"] == "completed"]
    return live, upcoming, completed


def fetch_scorer_dashboard(user):
    event_ids = fetch_scorer_assigned_event_ids(user)
    matches = fetch_scorer_matches(user, event_ids)
    live, upcoming, completed = _split_matches(matches)
    today = timezone.localdate().isoformat()

    todays_schedule = [
        m
        for m in matches
        if m.get("date") == today and m["status"] in ("upcoming", "live")
    ]

    display_name = user.username.replace("_", " ").title()
    if " " not in display_name and len(display_name) > 3:
        display_name = display_name.title()

    notifications = _build_notifications(matches, user)

    return {
        "greeting_name": display_name,
        "stats": {
            "assigned_matches": len([m for m in matches if m["status"] != "completed"]),
            "completed_matches": len(completed),
            "live_matches": len(live),
            "upcoming_matches": len(upcoming),
        },
        "todays_schedule": todays_schedule[:5],
        "notifications": notifications[:5],
        "assigned_activities": _assigned_activities(event_ids),
        "ongoing_matches": live,
        "upcoming_matches": upcoming,
    }


def _assigned_activities(event_ids):
    if not event_ids:
        return []

    activities = []
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT e.id, e.name, e.tournament_type, e.category,
                   COUNT(bm.id) AS match_count
            FROM events_event e
            INNER JOIN events_bracketmatch bm ON bm.event_id = e.id
            WHERE e.id = ANY(%s)
            GROUP BY e.id, e.name, e.tournament_type, e.category
            ORDER BY e.event_date, e.name
            """,
            [event_ids],
        )
        for row in cursor.fetchall():
            event_id, name, tournament_type, category, match_count = row
            activities.append(
                {
                    "id": event_id,
                    "title": name,
                    "description": (
                        f"{tournament_type or category or 'Tournament'} · "
                        f"{match_count} match{'es' if match_count != 1 else ''}"
                    ),
                    "activity_type": "bracket_scoring",
                    "event_id": event_id,
                }
            )
    return activities


def _build_notifications(matches, user):
    notes = []
    for match in matches:
        if match["status"] == "live":
            notes.append(
                {
                    "id": f"live_{match['id']}",
                    "title": f"{match['event_name']} is now live",
                    "body": "Start scoring now",
                    "time_display": match.get("time_display") or "Now",
                    "is_unread": True,
                }
            )
        elif match["status"] == "upcoming":
            notes.append(
                {
                    "id": f"assign_{match['id']}",
                    "title": "You have a match assigned",
                    "body": match["match_title"],
                    "time_display": match.get("time_display") or "",
                    "is_unread": True,
                }
            )

    for submission in fetch_scorer_history_entries(user).get("entries", [])[:3]:
        if submission["status"] == "approved":
            notes.append(
                {
                    "id": f"hist_{submission['id']}",
                    "title": f"{submission['event_name']} score approved",
                    "body": "By Tabulator",
                    "time_display": submission.get("submitted_at_display") or "",
                    "is_unread": False,
                }
            )

    return notes


def fetch_scorer_assignments(user, status_filter=None):
    matches = fetch_scorer_matches(user)
    live, upcoming, completed = _split_matches(matches)

    counts = {
        "all": len(matches),
        "live": len(live),
        "upcoming": len(upcoming),
        "completed": len(completed),
    }

    if status_filter == "live":
        filtered = live
    elif status_filter == "upcoming":
        filtered = upcoming
    elif status_filter == "completed":
        filtered = completed
    else:
        filtered = matches

    return {
        "assignments": filtered,
        "counts": counts,
        "today_display": timezone.localdate().strftime("%b %d, %Y"),
    }


def record_bracket_submission(user, match, score_a, score_b, match_status):
    """Record scorer submission. Tabulator approval stays pending until reviewed."""
    BracketScorerSubmission.objects.update_or_create(
        bracket_match_id=match["id"],
        scorer=user,
        defaults={
            "event_id": match.get("event_id"),
            "score_a": score_a,
            "score_b": score_b,
            "match_status": match_status or match.get("status") or "live",
        },
    )


def _approval_status_label(status):
    labels = {
        "pending": "Pending Verification",
        "approved": "Approved",
        "returned": "Returned",
    }
    return labels.get(status, (status or "pending").replace("_", " ").title())


def fetch_scorer_history_entries(user, status_filter=None, search=None):
    entries = _load_history_entries(user)

    if status_filter and status_filter != "all":
        entries = [e for e in entries if e["status"] == status_filter]

    if search:
        q = search.lower()
        entries = [
            e
            for e in entries
            if q in e["match_title"].lower()
            or q in e["teams_label"].lower()
            or q in (e.get("venue") or "").lower()
        ]

    counts = {"all": 0, "approved": 0, "pending": 0, "returned": 0}
    for entry in _load_history_entries(user):
        counts["all"] += 1
        key = entry["status"]
        if key in counts:
            counts[key] += 1

    return {"entries": entries, "counts": counts}


def _load_history_entries(user):
    entries = []

    bracket_subs = BracketScorerSubmission.objects.filter(scorer=user).order_by(
        "-submitted_at"
    )
    match_ids = [s.bracket_match_id for s in bracket_subs]

    bracket_lookup = {}
    if match_ids:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT
                    bm.id, bm.round_name, bm.status, bm.match_date, bm.match_time,
                    bm.venue, bm.score_a, bm.score_b, bm.updated_at,
                    e.id AS event_id, e.name AS event_name, e.category,
                    ta.name AS team_a_name, tb.name AS team_b_name
                FROM events_bracketmatch bm
                INNER JOIN events_event e ON e.id = bm.event_id
                LEFT JOIN events_bracketteam ta ON ta.id = bm.team_a_id
                LEFT JOIN events_bracketteam tb ON tb.id = bm.team_b_id
                WHERE bm.id = ANY(%s)
                """,
                [match_ids],
            )
            columns = [col[0] for col in cursor.description]
            for row in cursor.fetchall():
                data = dict(zip(columns, row))
                bracket_lookup[data["id"]] = data

    for sub in bracket_subs:
        row = bracket_lookup.get(sub.bracket_match_id)
        if not row:
            continue

        event_name = row.get("event_name") or "Event"
        round_name = row.get("round_name") or "Match"
        team_a = row.get("team_a_name") or "TBD"
        team_b = row.get("team_b_name") or "TBD"
        status = sub.approval_status

        entry = {
            "id": sub.id,
            "bracket_match_id": sub.bracket_match_id,
            "source": "bracket",
            "event_name": event_name,
            "match_title": f"{event_name} — {round_name}",
            "round_label_display": round_name,
            "teams_label": f"{team_a} vs {team_b}",
            "team_a": team_a,
            "team_b": team_b,
            "score_a": sub.score_a,
            "score_b": sub.score_b,
            "status": status,
            "status_label": _approval_status_label(status),
            "match_status": sub.match_status,
            "sport_icon": _sport_icon(event_name, row.get("category")),
            "venue": row.get("venue") or "",
            "date_display": _format_date(row.get("match_date")),
            "time_display": _format_time(row.get("match_time")),
            "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else "",
            "submitted_at_display": (
                sub.submitted_at.strftime("%b %d, %Y • %I:%M %p").lstrip("0")
                if sub.submitted_at
                else ""
            ),
        }

        entries.append(entry)

    legacy = ScorerSubmission.objects.filter(scorer=user).select_related(
        "match", "match__team_a", "match__team_b"
    )
    try:
        legacy_list = list(legacy)
    except Exception:
        legacy_list = []

    for sub in legacy_list:
        match = sub.match
        entry = {
            "id": f"legacy_{sub.id}",
            "source": "match",
            "event_name": match.sport,
            "match_title": match.title,
            "round_label_display": match.get_round_label_display(),
            "teams_label": f"{match.team_a.abbreviation} vs {match.team_b.abbreviation}",
            "team_a": match.team_a.abbreviation,
            "team_b": match.team_b.abbreviation,
            "score_a": sub.score_a,
            "score_b": sub.score_b,
            "status": sub.approval_status,
            "status_label": _approval_status_label(sub.approval_status),
            "match_status": sub.match_status,
            "sport_icon": _sport_icon(match.sport, match.sport),
            "venue": "",
            "date_display": "",
            "time_display": "",
            "submitted_at": sub.submitted_at.isoformat(),
            "submitted_at_display": (
                sub.submitted_at.strftime("%b %d, %Y • %I:%M %p").lstrip("0")
                if sub.submitted_at
                else ""
            ),
        }
        entries.append(entry)

    entries.sort(key=lambda e: e.get("submitted_at") or "", reverse=True)
    return entries


def fetch_scorer_match_detail(user, match_id):
    """Load a single assigned bracket match with display fields."""
    matches = fetch_scorer_matches(user)
    match = next((m for m in matches if m["id"] == match_id), None)
    return match


def fetch_scorer_profile(user):
    event_ids = fetch_scorer_assigned_event_ids(user)
    matches = fetch_scorer_matches(user, event_ids)
    live, upcoming, completed = _split_matches(matches)
    history = BracketScorerSubmission.objects.filter(scorer=user)
    legacy_count = 0
    try:
        legacy_count = ScorerSubmission.objects.filter(scorer=user).count()
    except Exception:
        legacy_count = 0

    month_start = date.today().replace(day=1)
    events_this_month = 0
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT COUNT(DISTINCT e.id)
            FROM events_event e
            WHERE e.id = ANY(%s)
              AND e.event_date >= %s
            """,
            [event_ids or [0], month_start],
        )
        events_this_month = cursor.fetchone()[0] or 0

    display_name = user.username.replace("_", " ").title()

    return {
        "display_name": display_name,
        "username": user.username,
        "email": user.email or "",
        "role": "SCORER",
        "location": "",
        "status": "ACTIVE" if user.is_active else "INACTIVE",
        "member_since_display": _format_date(user.date_joined.date())
        if user.date_joined
        else "—",
        "stats": {
            "matches_scored": history.count() + legacy_count,
            "completed": history.filter(approval_status="approved").count(),
            "pending": history.filter(approval_status="pending").count(),
            "events": max(len(event_ids), events_this_month),
        },
        "notification_count": len(
            [m for m in matches if m["status"] in ("live", "upcoming")]
        ),
    }
