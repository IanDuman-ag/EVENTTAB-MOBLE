"""Public viewer portal data — bracket + legacy matches + judging events."""

from datetime import date

from django.db import connection
from django.db.models import Q
from django.utils import timezone

from .bracket_data import fetch_bracket_matches
from .models import Activity, EventCategory, JudgingEvent, Match
from .serializers import MatchSerializer

MONTHS = [
    "Jan", "Feb", "Mar", "Apr", "May", "Jun",
    "Jul", "Aug", "Sep", "Oct", "Nov", "Dec",
]


def _format_date(value):
    if not value:
        return ""
    if isinstance(value, date):
        return f"{MONTHS[value.month - 1]} {value.day}, {value.year}"
    text = str(value)
    if "T" in text:
        text = text.split("T", 1)[0]
    try:
        parts = text.split("-")
        if len(parts) == 3:
            return f"{MONTHS[int(parts[1]) - 1]} {int(parts[2])}, {parts[0]}"
    except (ValueError, IndexError):
        pass
    return text


def _format_time(value):
    if not value:
        return ""
    text = str(value)
    if "T" in text:
        text = text.split("T", 1)[1][:5]
    return text[:5] if len(text) >= 5 else text


def _sport_icon(sport):
    sport = (sport or "").lower()
    if "basketball" in sport:
        return "basketball"
    if "volleyball" in sport:
        return "volleyball"
    if "football" in sport or "soccer" in sport:
        return "football"
    if "table tennis" in sport or "tennis" in sport:
        return "table_tennis"
    if "esport" in sport or "mobile legend" in sport:
        return "esports"
    if "dance" in sport or "sing" in sport or "perform" in sport:
        return "performing_arts"
    return "other"


def _category_group(name="", category_type=None, sport=None):
    text = f"{name or ''} {sport or ''}".lower()
    ctype = (category_type or "").lower()
    if ctype == "sports" or any(
        token in text
        for token in (
            "basketball",
            "volleyball",
            "football",
            "soccer",
            "table tennis",
            "tennis",
            "sport",
        )
    ):
        return "sports"
    if ctype == "socio_cultural" or any(
        token in text for token in ("dance", "sing", "perform", "music", "art", "cultural")
    ):
        return "performing_arts"
    if "pageant" in text or "miss" in text:
        return "pageants"
    return "others"


def _legacy_matches():
    matches = []
    try:
        for row in MatchSerializer(
            Match.objects.select_related("team_a", "team_b").all(),
            many=True,
        ).data:
            row["source"] = "match"
            matches.append(row)
    except Exception:
        pass
    return matches


def _enrich_viewer_match(match):
    team_a = match.get("team_a") or {}
    team_b = match.get("team_b") or {}
    sport = match.get("sport") or "other"
    event_name = match.get("event_name") or match.get("title") or "Event"
    round_display = match.get("round_label_display") or "Match"
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
    category_group = _category_group(
        event_name,
        match.get("category_type"),
        sport,
    )

    return {
        **match,
        "event_name": event_name,
        "match_title": match.get("match_title")
        or f"{event_name} — {round_display}",
        "teams_label": f"{team_a.get('name', 'TBD')} vs {team_b.get('name', 'TBD')}",
        "sport_icon": _sport_icon(sport),
        "category_group": category_group,
        "date_display": _format_date(match_date),
        "time_display": _format_time(match_time),
        "period_label": round_display if status == "live" else "",
        "has_scores": score_a is not None or score_b is not None,
    }


def fetch_combined_matches():
    combined = []
    for match in fetch_bracket_matches():
        event_name = match.get("sport", "Event")
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT name, category, venue, event_date, event_time
                FROM events_event WHERE id = %s
                """,
                [match.get("event_id")],
            )
            row = cursor.fetchone()
            if row:
                event_name = row[0]
                match = {
                    **match,
                    "event_name": row[0],
                    "sport": (row[1] or match.get("sport") or "other").lower(),
                }
                if not match.get("venue"):
                    match["venue"] = row[2] or ""
                if not match.get("scheduled_time") and row[3]:
                    event_time = row[4]
                    time_str = (
                        event_time.isoformat()
                        if event_time
                        else "00:00:00"
                    )
                    match["scheduled_time"] = f"{row[3]}T{time_str}"
        match["match_title"] = f"{event_name} — {match.get('round_label_display', 'Match')}"
        combined.append(_enrich_viewer_match(match))

    for match in _legacy_matches():
        match["event_name"] = match.get("title") or "Event"
        match["match_title"] = match.get("title") or "Match"
        combined.append(_enrich_viewer_match(match))

    return combined


def _split_matches(matches):
    live = [m for m in matches if m["status"] == "live"]
    upcoming = [m for m in matches if m["status"] == "upcoming"]
    completed = [m for m in matches if m["status"] == "completed"]
    return live, upcoming, completed


def _featured_match(matches):
    legacy_featured = next((m for m in matches if m.get("is_featured")), None)
    if legacy_featured:
        return legacy_featured
    live = [m for m in matches if m["status"] == "live"]
    if live:
        return live[0]
    upcoming = sorted(
        [m for m in matches if m["status"] == "upcoming"],
        key=lambda m: m.get("scheduled_time") or "",
    )
    return upcoming[0] if upcoming else None


def _build_team_rankings(matches, sport_filter=None):
    stats = {}

    def ensure_team(team):
        tid = team.get("id") or team.get("name")
        if tid not in stats:
            stats[tid] = {
                "team_id": team.get("id"),
                "name": team.get("name") or "Team",
                "abbreviation": team.get("abbreviation") or (team.get("name") or "?")[:4].upper(),
                "color": team.get("color") or "#00C5D9",
                "sport": "",
                "wins": 0,
                "losses": 0,
                "points": 0,
            }
        return stats[tid]

    for match in matches:
        if match.get("status") != "completed":
            continue
        sport = match.get("sport") or "other"
        if sport_filter and sport_filter not in ("all", "overall") and sport != sport_filter:
            continue
        team_a = match.get("team_a") or {}
        team_b = match.get("team_b") or {}
        score_a = match.get("score_a")
        score_b = match.get("score_b")
        if score_a is None or score_b is None:
            continue
        stat_a = ensure_team(team_a)
        stat_b = ensure_team(team_b)
        stat_a["sport"] = sport
        stat_b["sport"] = sport
        stat_a["points"] += score_a
        stat_b["points"] += score_b
        if score_a > score_b:
            stat_a["wins"] += 1
            stat_b["losses"] += 1
        elif score_b > score_a:
            stat_b["wins"] += 1
            stat_a["losses"] += 1

    rows = []
    for stat in stats.values():
        played = stat["wins"] + stat["losses"]
        pct = (stat["wins"] / played) if played else 0.0
        rows.append(
            {
                **stat,
                "played": played,
                "pct": round(pct, 3),
                "pct_display": f".{int(round(pct * 1000)):03d}" if played else "—",
            }
        )
    rows.sort(key=lambda r: (r["wins"], r["points"]), reverse=True)
    for idx, row in enumerate(rows, start=1):
        row["rank"] = idx
    return rows


def _judging_event_cards():
    cards = []
    for event in JudgingEvent.objects.select_related("category").all():
        status = event.status or "upcoming"
        if status == "active":
            status = "live"
        cards.append(
            _enrich_viewer_match(
                {
                    "id": f"judging_{event.id}",
                    "source": "judging",
                    "judging_event_id": event.id,
                    "title": event.title,
                    "event_name": event.title,
                    "match_title": event.title,
                    "sport": event.category.name if event.category else "other",
                    "category_type": event.category.category_type if event.category else None,
                    "teams_label": event.category.name if event.category else "Judging Event",
                    "team_a": {"name": event.title, "abbreviation": "EVT", "color": "#00C5D9"},
                    "team_b": {"name": event.venue or "Venue TBD", "abbreviation": "LOC", "color": "#8B8D91"},
                    "score_a": None,
                    "score_b": None,
                    "scheduled_time": f"{event.date}T{event.time or '00:00:00'}" if event.date else "",
                    "status": status,
                    "venue": event.venue or "",
                    "round_label_display": "Final Round" if status == "live" else "Scheduled",
                    "period_label": "Judging" if status == "live" else "On Stage" if status == "live" else "",
                    "status_detail": "Judging" if status == "live" else "",
                }
            )
        )
    return cards


def fetch_viewer_dashboard():
    matches = fetch_combined_matches()
    judging = _judging_event_cards()
    all_items = matches + judging
    live, upcoming, completed = _split_matches(all_items)
    featured = _featured_match(all_items)
    ongoing = live + upcoming[: max(0, 6 - len(live))]
    rankings = _build_team_rankings(matches)[:3]

    portal_events = _portal_event_count()

    return {
        "counts": {
            "live": len(live),
            "upcoming": len(upcoming),
            "completed": len(completed),
            "total": len(all_items) + max(portal_events - len(matches), 0),
        },
        "featured": featured,
        "ongoing": ongoing[:6],
        "top_rankings": rankings,
        "notification_count": len(live),
    }


def _portal_event_count():
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM events_event WHERE status = 'active'")
        row = cursor.fetchone()
        return row[0] if row else 0


def fetch_viewer_events(status_filter=None, category_filter=None, search=None):
    matches = fetch_combined_matches()
    judging = _judging_event_cards()
    items = matches + judging

    if status_filter and status_filter != "all":
        items = [i for i in items if i.get("status") == status_filter]

    if category_filter and category_filter not in ("all", ""):
        items = [i for i in items if i.get("category_group") == category_filter]

    if search:
        q = search.lower()
        items = [
            i
            for i in items
            if q in (i.get("match_title") or "").lower()
            or q in (i.get("teams_label") or "").lower()
            or q in (i.get("venue") or "").lower()
            or q in (i.get("sport") or "").lower()
        ]

    live, upcoming, completed = _split_matches(items)
    counts = {
        "all": len(items),
        "live": len(live),
        "upcoming": len(upcoming),
        "completed": len(completed),
    }

    return {"events": items, "counts": counts}


def fetch_viewer_live(sport_filter=None):
    matches = fetch_combined_matches()
    judging = _judging_event_cards()
    all_items = matches + judging
    live, upcoming, _completed = _split_matches(all_items)

    if sport_filter and sport_filter not in ("all", ""):
        live = [m for m in live if (m.get("sport") or "") == sport_filter]
        upcoming = [m for m in upcoming if (m.get("sport") or "") == sport_filter]

    featured = live[0] if live else None
    scoreboard = live[:8]

    updates = _recent_activity_updates(limit=10)

    for match in live[:5]:
        score_a = match.get("score_a")
        score_b = match.get("score_b")
        if score_a is None or score_b is None:
            continue
        updates.insert(
            0,
            {
                "id": f"live_{match.get('id')}",
                "title": match.get("teams_label") or match.get("match_title") or "Live update",
                "description": f"Score is now {score_a} - {score_b}.",
                "icon": _sport_icon(match.get("sport")),
                "time_display": "Just now",
            },
        )

    sports = sorted({m.get("sport") or "other" for m in all_items if m.get("sport")})

    return {
        "featured": featured,
        "ongoing": (live + judging[: max(0, 4 - len(live))])[:8],
        "scoreboard": scoreboard,
        "updates": updates[:12],
        "sports": sports,
        "live_count": len(live),
    }


def _recent_activity_updates(limit=10):
    """Activity feed without joining legacy Team rows (schema may differ)."""
    updates = []
    try:
        for activity in Activity.objects.order_by("-created_at")[:limit]:
            updates.append(
                {
                    "id": activity.id,
                    "title": activity.title,
                    "description": activity.description,
                    "icon": activity.icon,
                    "time_display": _activity_time(activity.created_at),
                }
            )
    except Exception:
        pass
    return updates


def _activity_time(created_at):
    diff = timezone.now() - created_at
    if diff.days > 0:
        return f"{diff.days}d ago"
    if diff.seconds >= 3600:
        return f"{diff.seconds // 3600}h ago"
    if diff.seconds >= 60:
        return f"{diff.seconds // 60}m ago"
    return "Just now"


def fetch_viewer_rankings(sport_filter=None):
    matches = fetch_combined_matches()
    rows = _build_team_rankings(matches, sport_filter=sport_filter)
    sports = sorted({m.get("sport") or "other" for m in matches if m.get("sport")})
    return {"rankings": rows, "sports": ["overall", *sports]}


def fetch_viewer_profile():
    categories = EventCategory.objects.count()
    judging_count = JudgingEvent.objects.count()
    matches = fetch_combined_matches()
    live, upcoming, completed = _split_matches(matches)

    return {
        "display_name": "Guest Viewer",
        "mode": "VIEWER MODE",
        "is_guest": True,
        "stats": {
            "saved_events": 0,
            "recently_viewed": 0,
            "live_events": len(live),
            "categories": categories,
            "judging_events": judging_count,
        },
    }
