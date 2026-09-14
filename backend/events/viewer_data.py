"""Public viewer portal data — bracket + legacy matches + judging events."""

from datetime import date

from django.db import connection
from django.db.models import Q
from django.utils import timezone

from .bracket_data import fetch_bracket_matches
from .models import Activity, EventCategory, JudgingEvent, Match, Team
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
                SELECT name, category, venue, event_date, event_time,
                       sport_type, sport_custom_name
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
                    "sport": (
                        row[6]
                        or row[5]
                        or row[1]
                        or match.get("sport")
                        or "other"
                    ).lower(),
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


def _match_category_bucket(match):
    """Map a match into academic | esports | sports | socio_cultural."""
    ctype = (match.get("category_type") or "").lower().replace("-", "_")
    if ctype in ("academic", "esports", "sports", "socio_cultural"):
        return ctype
    text = " ".join(
        str(v or "")
        for v in (
            match.get("sport"),
            match.get("event_name"),
            match.get("title"),
            match.get("category_name"),
        )
    ).lower()
    if any(t in text for t in ("esport", "mobile legend", "valorant", "dota", "mlbb")):
        return "esports"
    if any(
        t in text
        for t in (
            "basketball",
            "volleyball",
            "football",
            "soccer",
            "tennis",
            "sport",
        )
    ):
        return "sports"
    if any(
        t in text
        for t in ("dance", "sing", "perform", "music", "art", "cultural", "socio")
    ):
        return "socio_cultural"
    if any(t in text for t in ("academic", "quiz", "debate", "pageant", "orator")):
        return "academic"
    return "others"


def _team_catalog():
    """id/name → team fields for logo enrichment."""
    by_id = {}
    by_name = {}
    try:
        for t in Team.objects.all():
            payload = {
                "team_id": t.id,
                "name": t.name,
                "abbreviation": t.abbreviation,
                "logo_icon": t.logo_icon or "",
                "color": t.color or "#00C5D9",
            }
            by_id[t.id] = payload
            by_name[(t.name or "").strip().lower()] = payload
            by_name[(t.abbreviation or "").strip().lower()] = payload
    except Exception:
        pass
    return by_id, by_name


def _build_team_rankings(matches, sport_filter=None, category_filter=None):
    from .tabulator_data import approved_bracket_match_ids, approved_legacy_match_ids

    approved_bracket = approved_bracket_match_ids()
    approved_legacy = approved_legacy_match_ids()
    by_id, by_name = _team_catalog()
    stats = {}
    cat_filter = (category_filter or "").lower().strip()
    if cat_filter in ("all", "overall", "all_events", ""):
        cat_filter = None
    sport_filter = (sport_filter or "").lower().strip()
    if sport_filter in ("all", "overall", ""):
        sport_filter = None

    def ensure_team(team):
        tid = team.get("id") or team.get("name")
        if tid not in stats:
            catalog = None
            if team.get("id") is not None:
                catalog = by_id.get(team.get("id"))
            if catalog is None:
                catalog = by_name.get((team.get("name") or "").strip().lower())
            if catalog is None:
                catalog = by_name.get((team.get("abbreviation") or "").strip().lower())
            stats[tid] = {
                "team_id": (catalog or {}).get("team_id") or team.get("id"),
                "name": (catalog or {}).get("name") or team.get("name") or "Team",
                "abbreviation": (catalog or {}).get("abbreviation")
                or team.get("abbreviation")
                or (team.get("name") or "?")[:4].upper(),
                "logo_icon": (catalog or {}).get("logo_icon")
                or team.get("logo_icon")
                or "",
                "color": (catalog or {}).get("color")
                or team.get("color")
                or "#00C5D9",
                "sport": "",
                "category": "",
                "wins": 0,
                "losses": 0,
                "points": 0,
                "events": 0,
                "_match_ids": set(),
            }
        return stats[tid]

    for match in matches:
        if match.get("status") != "completed":
            continue

        # Official results only — tabulator-approved submissions.
        mid = match.get("id")
        source = match.get("source") or ""
        is_official = False
        if source == "bracket" or match.get("bracket_match_id") or "bracket" in str(source):
            is_official = mid in approved_bracket
        elif source == "legacy" or match.get("match_id") or source == "match":
            is_official = mid in approved_legacy
        else:
            is_official = mid in approved_bracket or mid in approved_legacy
        if not is_official:
            continue

        sport = match.get("sport") or "other"
        bucket = _match_category_bucket(match)
        if sport_filter and sport != sport_filter:
            continue
        if cat_filter and bucket != cat_filter:
            continue

        team_a = match.get("team_a") or {}
        team_b = match.get("team_b") or {}
        score_a = match.get("score_a")
        score_b = match.get("score_b")
        if score_a is None or score_b is None:
            continue
        # Skip synthetic judging placeholder teams.
        if team_a.get("abbreviation") == "EVT" and team_b.get("abbreviation") == "LOC":
            continue

        stat_a = ensure_team(team_a)
        stat_b = ensure_team(team_b)
        for stat in (stat_a, stat_b):
            stat["sport"] = sport
            stat["category"] = bucket
            if mid not in stat["_match_ids"]:
                stat["_match_ids"].add(mid)
                stat["events"] += 1
        stat_a["points"] += int(score_a)
        stat_b["points"] += int(score_b)
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
        row = {
            k: v
            for k, v in stat.items()
            if k != "_match_ids"
        }
        rows.append(
            {
                **row,
                "played": played,
                "pct": round(pct, 3),
                "pct_display": f".{int(round(pct * 1000)):03d}" if played else "—",
            }
        )
    rows.sort(key=lambda r: (r["points"], r["wins"], r["events"]), reverse=True)
    for idx, row in enumerate(rows, start=1):
        row["rank"] = idx
    return rows


def _portal_judging_event_metadata():
    """Return the public portal configuration linked to each judging record."""
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT judging_event_id, scoring_method, publication_status
                FROM events_event
                WHERE judging_event_id IS NOT NULL
                """
            )
            return {
                judging_event_id: {
                    "scoring_method": (scoring_method or "").strip().lower(),
                    "publication_status": (publication_status or "")
                    .strip()
                    .lower(),
                }
                for judging_event_id, scoring_method, publication_status
                in cursor.fetchall()
            }
    except Exception:
        # Some deployments only use the Django judging tables.
        return {}


def _judging_event_cards():
    cards = []
    portal_metadata = _portal_judging_event_metadata()
    for event in JudgingEvent.objects.select_related("category").all():
        metadata = portal_metadata.get(event.id)
        if metadata:
            # The portal event is authoritative. Match-based portal events may
            # have a JudgingEvent mirror for assignments, but belong in the
            # match feed and must not appear as criteria-based duplicates.
            if metadata["scoring_method"] in {
                "match",
                "score",
                "score_based",
                "bracket",
            }:
                continue
            if metadata["publication_status"] not in {"", "published"}:
                continue
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
    ongoing = live[:6]
    rankings = _build_team_rankings(matches)[:3]

    from .tabulator_data import approved_bracket_match_ids, approved_legacy_match_ids

    approved_b = approved_bracket_match_ids()
    approved_l = approved_legacy_match_ids()
    official_results = []
    for m in completed:
        mid = m.get("id")
        src = m.get("source") or ""
        if src == "judging" and (m.get("status") or "") == "completed":
            official_results.append({**m, "result_type": "criteria"})
        elif src == "bracket" and mid in approved_b:
            official_results.append({**m, "result_type": "match"})
        elif src in ("match", "legacy") and mid in approved_l:
            official_results.append({**m, "result_type": "match"})
        elif mid in approved_b or mid in approved_l:
            official_results.append({**m, "result_type": "match"})

    portal_events = _portal_event_count()
    announcements = fetch_viewer_announcements()[:3]
    notifications = fetch_viewer_notifications()

    return {
        "welcome_title": "Welcome to EventTab",
        "intramurals_banner": "Intramurals 2026 — Live Results & Standings",
        "counts": {
            "live": len(live),
            "upcoming": len(upcoming),
            "completed": len(completed),
            "total": len(all_items) + max(portal_events - len(matches), 0),
        },
        "featured": featured,
        "ongoing": ongoing,
        "upcoming": upcoming[:6],
        "latest_results": official_results[:8],
        "top_rankings": rankings,
        "announcements_preview": announcements,
        "notification_count": sum(1 for n in notifications if n.get("is_unread")),
        "notifications": notifications[:10],
    }


def _portal_event_count():
    with connection.cursor() as cursor:
        cursor.execute("SELECT COUNT(*) FROM events_event WHERE status = 'active'")
        row = cursor.fetchone()
        return row[0] if row else 0


def _group_match_events(matches):
    """Collapse a tournament's individual matches into one viewer event card."""
    grouped = {}
    for match in matches:
        event_id = match.get("event_id")
        event_name = (match.get("event_name") or "").strip().lower()
        sport = (match.get("sport") or "").strip().lower()
        if event_id is not None:
            key = ("event", str(event_id))
        elif event_name:
            key = ("name", event_name, sport)
        else:
            key = (
                "match",
                str(match.get("source") or ""),
                str(match.get("id") or id(match)),
            )
        grouped.setdefault(key, []).append(match)

    status_priority = {"live": 0, "ongoing": 0, "upcoming": 1, "completed": 2}
    events = []
    for matches_for_event in grouped.values():
        representative = min(
            matches_for_event,
            key=lambda match: (
                status_priority.get((match.get("status") or "").lower(), 3),
                match.get("scheduled_time") or "",
            ),
        )
        statuses = {
            (match.get("status") or "").lower() for match in matches_for_event
        }
        if statuses.intersection({"live", "ongoing"}):
            event_status = "live"
        elif "upcoming" in statuses:
            event_status = "upcoming"
        elif statuses == {"completed"}:
            event_status = "completed"
        else:
            event_status = representative.get("status") or "upcoming"
        events.append(
            {
                **representative,
                "status": event_status,
                "match_count": len(matches_for_event),
            }
        )
    return events


def fetch_viewer_events(status_filter=None, category_filter=None, search=None, event_type=None):
    matches = _group_match_events(fetch_combined_matches())
    judging = _judging_event_cards()

    items = []
    for m in matches:
        items.append(
            {
                **m,
                "event_type": "match",
                "event_classification": "Match-Based",
                "division": m.get("tournament_type") or m.get("round_label_display") or "",
            }
        )
    for j in judging:
        items.append(
            {
                **j,
                "event_type": "criteria",
                "event_classification": "Criteria-Based",
                "division": j.get("category_type") or "",
            }
        )

    if event_type in ("match", "criteria"):
        items = [i for i in items if i.get("event_type") == event_type]

    if status_filter and status_filter != "all":
        items = [i for i in items if i.get("status") == status_filter]

    if category_filter and category_filter not in ("all", ""):
        items = [
            i
            for i in items
            if i.get("category_group") == category_filter
            or (i.get("category_type") or "") == category_filter
        ]

    if search:
        q = search.lower()
        items = [
            i
            for i in items
            if q in (i.get("match_title") or "").lower()
            or q in (i.get("event_name") or "").lower()
            or q in (i.get("title") or "").lower()
            or q in (i.get("teams_label") or "").lower()
            or q in (i.get("venue") or "").lower()
            or q in (i.get("sport") or "").lower()
        ]

    items.sort(key=lambda i: i.get("scheduled_time") or i.get("date_display") or "")

    live, upcoming, completed = _split_matches(items)
    counts = {
        "all": len(items),
        "live": len(live),
        "upcoming": len(upcoming),
        "completed": len(completed),
        "match": sum(1 for i in items if i.get("event_type") == "match"),
        "criteria": sum(1 for i in items if i.get("event_type") == "criteria"),
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


def fetch_viewer_rankings(sport_filter=None, category_filter=None):
    matches = fetch_combined_matches()
    rows = _build_team_rankings(
        matches,
        sport_filter=sport_filter,
        category_filter=category_filter,
    )
    sports = sorted({m.get("sport") or "other" for m in matches if m.get("sport")})
    categories = [
        {"id": "all", "label": "All Events", "icon": "grid"},
        {"id": "academic", "label": "Academic", "icon": "school"},
        {"id": "esports", "label": "Esports", "icon": "sports_esports"},
        {"id": "sports", "label": "Sports", "icon": "sports_soccer"},
        {"id": "socio_cultural", "label": "Socio Cultural", "icon": "theater_comedy"},
    ]
    return {
        "rankings": rows,
        "sports": ["overall", *sports],
        "categories": categories,
    }


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


def fetch_viewer_announcements(limit=30):
    items = []
    try:
        for activity in Activity.objects.filter(activity_type="announcement").order_by(
            "-created_at"
        )[:limit]:
            items.append(
                {
                    "id": activity.id,
                    "title": activity.title,
                    "body": activity.description or "",
                    "icon": activity.icon or "campaign",
                    "created_at": activity.created_at.isoformat() if activity.created_at else "",
                    "time_display": _activity_time(activity.created_at)
                    if activity.created_at
                    else "",
                }
            )
    except Exception:
        pass
    # Fallback synthetic announcements from live/upcoming if none
    if not items:
        matches = fetch_combined_matches()
        live, upcoming, _ = _split_matches(matches)
        for m in (live + upcoming)[:5]:
            items.append(
                {
                    "id": f"auto_{m.get('id')}",
                    "title": m.get("event_name") or m.get("match_title") or "Event update",
                    "body": f"{m.get('status', '').title()} at {m.get('venue') or 'TBD'}",
                    "icon": "event",
                    "created_at": m.get("scheduled_time") or "",
                    "time_display": m.get("date_display") or "",
                }
            )
    return items


def fetch_viewer_notifications():
    notes = []
    matches = fetch_combined_matches()
    live, upcoming, completed = _split_matches(matches)
    for m in live[:5]:
        notes.append(
            {
                "id": f"live_{m.get('id')}",
                "title": "Event Starting Soon" if m.get("status") == "upcoming" else "Live Now",
                "body": m.get("match_title") or m.get("event_name") or "Match is live",
                "time": m.get("scheduled_time") or "",
                "time_display": m.get("time_display") or "Now",
                "is_unread": True,
                "type": "live",
                "event_ref": {"type": "match", "id": m.get("id"), "source": m.get("source")},
            }
        )
    from .tabulator_data import approved_bracket_match_ids, approved_legacy_match_ids

    ab = approved_bracket_match_ids()
    al = approved_legacy_match_ids()
    for m in completed[:8]:
        mid = m.get("id")
        if mid in ab or mid in al:
            notes.append(
                {
                    "id": f"result_{mid}",
                    "title": "Match Result Published",
                    "body": m.get("match_title") or m.get("teams_label") or "Result available",
                    "time": m.get("scheduled_time") or "",
                    "time_display": m.get("date_display") or "",
                    "is_unread": False,
                    "type": "result",
                    "event_ref": {"type": "match", "id": mid, "source": m.get("source")},
                }
            )
    rankings = _build_team_rankings(matches)
    if rankings:
        top = rankings[0]
        notes.append(
            {
                "id": "leaderboard_top",
                "title": "Leaderboard Updated",
                "body": f"{top.get('name')} leads with {top.get('points')} pts",
                "time": timezone.now().isoformat(),
                "time_display": "Today",
                "is_unread": True,
                "type": "leaderboard",
                "event_ref": {"type": "leaderboard"},
            }
        )
    return notes


def fetch_viewer_about():
    return {
        "system_description": (
            "EventTab Intramurals Management System provides live schedules, "
            "brackets, official results, and championship standings for the school community."
        ),
        "school_name": "EventTab University",
        "current_intramurals": "Intramurals 2026",
        "version": "1.0.0",
        "contact": "events@eventtab.local",
    }


def fetch_viewer_bracket(event_id=None):
    """Published bracket structure for viewers (official scores only)."""
    from .bracket_data import fetch_bracket_events
    from .tabulator_data import approved_bracket_match_ids

    approved = approved_bracket_match_ids()
    events = fetch_bracket_events()
    if event_id is not None:
        events = [e for e in events if e.get("event_id") == int(event_id)]

    for event in events:
        for rnd in event.get("rounds") or []:
            for match in rnd.get("matches") or []:
                mid = match.get("id")
                official = mid in approved
                match["is_official"] = official
                match["is_current"] = (match.get("status") or "") == "live"
                if not official and (match.get("status") or "") == "completed":
                    # Hide unpublished final scores from viewers
                    match["score_a"] = None
                    match["score_b"] = None
                    match["winner_side"] = None
                    match["status_display"] = "Awaiting Official Result"
    return {"events": events}


def fetch_viewer_match_event_detail(match_id):
    matches = fetch_combined_matches()
    match = next((m for m in matches if str(m.get("id")) == str(match_id)), None)
    if match is None:
        return None

    event_name = match.get("event_name") or match.get("sport") or "Event"
    related = [
        m
        for m in matches
        if (m.get("event_name") or m.get("sport")) == event_name
        or m.get("event_id") == match.get("event_id")
    ]
    from .tabulator_data import approved_bracket_match_ids, approved_legacy_match_ids

    ab = approved_bracket_match_ids()
    al = approved_legacy_match_ids()

    schedule = []
    results = []
    for i, m in enumerate(related, start=1):
        card = {
            **m,
            "game_number": m.get("match_number") or i,
            "round": m.get("round_label_display") or m.get("round_label") or "",
            "team_a_name": (m.get("team_a") or {}).get("name") or "TBD",
            "team_b_name": (m.get("team_b") or {}).get("name") or "TBD",
        }
        schedule.append(card)
        mid = m.get("id")
        src = m.get("source") or ""
        official = (src == "bracket" and mid in ab) or (
            src in ("match", "legacy") and mid in al
        ) or (mid in ab or mid in al)
        if (m.get("status") or "") == "completed" and official:
            sa = m.get("score_a")
            sb = m.get("score_b")
            winner = None
            if sa is not None and sb is not None:
                if sa > sb:
                    winner = card["team_a_name"]
                elif sb > sa:
                    winner = card["team_b_name"]
            results.append(
                {
                    **card,
                    "final_score": f"{sa} - {sb}" if sa is not None else "—",
                    "winner": winner or "—",
                    "published": True,
                }
            )

    teams = set()
    for m in related:
        for key in ("team_a", "team_b"):
            t = m.get(key) or {}
            if t.get("name") and t.get("abbreviation") not in ("TBD", "EVT", "LOC"):
                teams.add(t.get("name"))

    bracket = fetch_viewer_bracket(match.get("event_id"))

    return {
        "event_type": "match",
        "overview": {
            "id": match.get("id"),
            "event_id": match.get("event_id"),
            "title": event_name,
            "category": match.get("sport") or match.get("category_group") or "",
            "division": match.get("tournament_type") or "",
            "event_classification": "Match-Based",
            "venue": match.get("venue") or "",
            "date_display": match.get("date_display") or "",
            "description": match.get("notes") or f"{event_name} tournament.",
            "tournament_format": match.get("tournament_type")
            or match.get("round_label_display")
            or "Single Elimination",
            "team_count": len(teams),
            "status": match.get("status"),
        },
        "schedule": schedule,
        "bracket": bracket,
        "results": results,
    }


def fetch_viewer_criteria_event_detail(judging_event_id):
    try:
        event = JudgingEvent.objects.select_related("category").get(id=judging_event_id)
    except JudgingEvent.DoesNotExist:
        return None

    from .models import Candidate, JudgeScore, JudgingStage
    from decimal import Decimal

    stages = list(event.stages.all().order_by("order", "id"))
    active = next((s for s in stages if s.is_active), stages[0] if stages else None)
    stage_payload = [
        {
            "id": s.id,
            "name": s.name,
            "description": s.description,
            "status": s.status,
            "is_active": s.is_active,
            "order": s.order,
        }
        for s in stages
    ]
    if not stage_payload:
        stage_payload = [
            {
                "id": None,
                "name": "Main Stage",
                "description": event.description or "",
                "status": "scoring_open" if event.status == "active" else event.status,
                "is_active": event.status == "active",
                "order": 0,
            }
        ]
        active_name = "Main Stage"
    else:
        active_name = active.name if active else stage_payload[0]["name"]

    # Contestants — only show; qualification status from eligibility when published stage
    contestants = []
    for cand in Candidate.objects.filter(event=event).order_by("number"):
        status_label = "Competing"
        if event.status == "completed":
            status_label = "Finalist"
        contestants.append(
            {
                "id": cand.id,
                "number": cand.number,
                "name": cand.name,
                "department": cand.department or cand.description or "",
                "photo": cand.photo.url if cand.photo else None,
                "status": status_label,
            }
        )

    # Official published results (approved scores only)
    results = []
    show_scores = True
    standings = []
    for cand in Candidate.objects.filter(event=event).order_by("number"):
        scores_qs = JudgeScore.objects.filter(
            candidate=cand, approval_status="approved"
        ).select_related("criterion")
        if not scores_qs.exists():
            continue
        total = Decimal("0")
        for js in scores_qs:
            if js.criterion.max_score > 0:
                total += js.score * js.criterion.weight_percent / js.criterion.max_score
        standings.append(
            {
                "candidate_id": cand.id,
                "name": cand.name,
                "number": cand.number,
                "department": cand.department or "",
                "total_score": float(round(total, 1)),
            }
        )
    standings.sort(key=lambda r: r["total_score"], reverse=True)
    award_titles = ["Champion", "First Runner-Up", "Second Runner-Up"]
    for i, row in enumerate(standings):
        row["rank"] = i + 1
        row["award"] = award_titles[i] if i < len(award_titles) else f"#{i + 1}"
        if i < 3:
            contestants_map = {c["id"]: c for c in contestants}
            if row["candidate_id"] in contestants_map:
                contestants_map[row["candidate_id"]]["status"] = (
                    "Winner" if i == 0 else "Finalist"
                )
        results.append(
            {
                "rank": row["rank"],
                "contestant_name": row["name"],
                "department": row["department"],
                "award": row["award"],
                "score": row["total_score"] if show_scores else None,
            }
        )

    # Mark qualified from eligibility for active stage (only if faculty confirmed)
    if active and active.id and active.status in (
        "qualifiers_confirmed",
        "next_stage_open",
        "completed",
    ):
        from .models import CandidateStageEligibility

        qualified = set(
            CandidateStageEligibility.objects.filter(
                stage=active, is_qualified=True
            ).values_list("candidate_id", flat=True)
        )
        if qualified:
            for c in contestants:
                if c["id"] in qualified:
                    c["status"] = "Qualified"

    awards = [
        {"title": r["award"], "recipient": r["contestant_name"], "department": r["department"]}
        for r in results[:3]
    ]

    return {
        "event_type": "criteria",
        "overview": {
            "id": event.id,
            "title": event.title,
            "category": event.category.name if event.category_id else "",
            "category_type": event.category.category_type if event.category_id else "",
            "division": event.category.category_type if event.category_id else "",
            "event_classification": "Criteria-Based",
            "venue": event.venue,
            "date_display": _format_date(event.date),
            "time_display": _format_time(event.time),
            "description": event.description or "",
            "competition_structure": " / ".join(s["name"] for s in stage_payload),
            "contestant_count": len(contestants),
            "status": event.status,
            "current_stage": active_name,
            "faculty_in_charge": event.faculty_in_charge or "",
        },
        "schedule": {
            "date_display": _format_date(event.date),
            "time_display": _format_time(event.time),
            "venue": event.venue,
            "current_stage": active_name,
            "stages": stage_payload,
        },
        "contestants": contestants,
        "results": results if event.status == "completed" or results else [],
        "awards": awards if event.status == "completed" or awards else [],
        "show_scores": show_scores,
    }
