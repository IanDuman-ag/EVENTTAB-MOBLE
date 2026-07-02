"""Read and update tournament bracket data from the EventTab admin portal tables."""

from django.db import connection

ROUND_ORDER = {
    "quarterfinals": 1,
    "quarterfinal": 1,
    "semifinals": 2,
    "semifinal": 2,
    "final": 3,
    "finals": 3,
}

BRACKET_TO_APP_STATUS = {
    "pending": "upcoming",
    "scheduled": "upcoming",
    "upcoming": "upcoming",
    "live": "live",
    "in_progress": "live",
    "ongoing": "live",
    "completed": "completed",
    "finished": "completed",
    "done": "completed",
    "cancelled": "cancelled",
}

APP_TO_BRACKET_STATUS = {
    "upcoming": "pending",
    "live": "live",
    "completed": "completed",
    "cancelled": "cancelled",
}

_BRACKET_MATCH_SQL = """
    SELECT
        bm.id,
        bm.match_number,
        bm.round_name,
        bm.status,
        bm.match_date,
        bm.match_time,
        bm.venue,
        bm.score_a,
        bm.score_b,
        bm.event_id,
        e.name AS event_name,
        e.category AS event_category,
        e.tournament_type,
        e.venue AS event_venue,
        ta.id AS team_a_id,
        ta.name AS team_a_name,
        da.code AS team_a_abbr,
        da.delegation_color AS team_a_color,
        tb.id AS team_b_id,
        tb.name AS team_b_name,
        db.code AS team_b_abbr,
        db.delegation_color AS team_b_color
    FROM events_bracketmatch bm
    INNER JOIN events_event e ON e.id = bm.event_id
    LEFT JOIN events_bracketteam ta ON ta.id = bm.team_a_id
    LEFT JOIN events_department da ON da.id = ta.department_id
    LEFT JOIN events_bracketteam tb ON tb.id = bm.team_b_id
    LEFT JOIN events_department db ON db.id = tb.department_id
    WHERE e.status = 'active'
    ORDER BY bm.event_id, bm.match_number
"""


def _parse_score(value):
    if value is None:
        return None
    text = str(value).strip()
    if not text:
        return None
    try:
        return int(text)
    except ValueError:
        return None


def _map_status(bracket_status):
    return BRACKET_TO_APP_STATUS.get(
        (bracket_status or "pending").lower(),
        "upcoming",
    )


def _round_sort_key(round_name):
    return ROUND_ORDER.get((round_name or "").lower().strip(), 99)


def _team_payload(team_id, name, abbr, color):
    display = name or "TBD"
    return {
        "id": team_id,
        "name": display,
        "abbreviation": abbr or (display[:4].upper() if display != "TBD" else "TBD"),
        "color": color or "#8B8D91",
    }


def serialize_bracket_row(row):
    """Convert a SQL row dict into the match shape used by the Flutter scorer UI."""
    team_a_name = row.get("team_a_name")
    team_b_name = row.get("team_b_name")
    event_name = row.get("event_name") or "Event"
    round_name = row.get("round_name") or "Round"
    match_number = row.get("match_number")

    if team_a_name and team_b_name:
        title = f"{team_a_name} vs {team_b_name}"
    else:
        title = f"{event_name} — {round_name} (Match {match_number})"

    scheduled = None
    match_date = row.get("match_date")
    match_time = row.get("match_time")
    if match_date and match_time:
        scheduled = f"{match_date}T{match_time}"
    elif match_date:
        scheduled = f"{match_date}T00:00:00"

    return {
        "id": row["id"],
        "source": "bracket",
        "event_id": row["event_id"],
        "title": title,
        "sport": (row.get("event_category") or "other").lower(),
        "round_label": round_name.lower().replace(" ", "_"),
        "round_label_display": round_name,
        "match_number": match_number,
        "team_a": _team_payload(
            row.get("team_a_id"),
            team_a_name,
            row.get("team_a_abbr"),
            row.get("team_a_color"),
        ),
        "team_b": _team_payload(
            row.get("team_b_id"),
            team_b_name,
            row.get("team_b_abbr"),
            row.get("team_b_color"),
        ),
        "score_a": _parse_score(row.get("score_a")),
        "score_b": _parse_score(row.get("score_b")),
        "scheduled_time": scheduled,
        "status": _map_status(row.get("status")),
        "venue": row.get("venue") or row.get("event_venue") or "",
        "tournament_type": row.get("tournament_type") or "",
    }


def _rows_to_dicts(cursor):
    columns = [col[0] for col in cursor.description]
    return [dict(zip(columns, row)) for row in cursor.fetchall()]


def fetch_bracket_matches():
    with connection.cursor() as cursor:
        cursor.execute(_BRACKET_MATCH_SQL)
        return [serialize_bracket_row(row) for row in _rows_to_dicts(cursor)]


def fetch_bracket_events():
    """Group bracket matches by event and round for the Bracket tab."""
    matches = fetch_bracket_matches()
    events_map = {}

    for match in matches:
        event_id = match["event_id"]
        event_entry = events_map.setdefault(
            event_id,
            {
                "event_id": event_id,
                "event_name": match["title"].split(" — ")[0]
                if " — " in match["title"]
                else match.get("sport", "Event"),
                "category": match.get("sport", ""),
                "tournament_type": match.get("tournament_type", ""),
                "rounds": {},
            },
        )

        # Prefer real event name from first match with event context
        if match.get("tournament_type"):
            event_entry["tournament_type"] = match["tournament_type"]

        round_name = match["round_label_display"]
        round_entry = event_entry["rounds"].setdefault(
            round_name,
            {
                "round_label": match["round_label"],
                "round_label_display": round_name,
                "matches": [],
            },
        )
        round_entry["matches"].append(match)

    events = []
    for event_id in sorted(events_map.keys()):
        event_data = events_map[event_id]
        # Fix event name from SQL
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT name, category, tournament_type FROM events_event WHERE id = %s",
                [event_id],
            )
            row = cursor.fetchone()
            if row:
                event_data["event_name"] = row[0]
                event_data["category"] = row[1]
                event_data["tournament_type"] = row[2] or ""

        rounds = sorted(
            event_data["rounds"].values(),
            key=lambda r: _round_sort_key(r["round_label_display"]),
        )
        events.append(
            {
                "event_id": event_data["event_id"],
                "event_name": event_data["event_name"],
                "category": event_data["category"],
                "tournament_type": event_data["tournament_type"],
                "rounds": rounds,
            }
        )

    return events


def fetch_assigned_activities():
    """Active bracket events the scorer should work on."""
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT e.id, e.name, e.tournament_type, e.category,
                   COUNT(bm.id) AS match_count
            FROM events_event e
            INNER JOIN events_bracketmatch bm ON bm.event_id = e.id
            WHERE e.status = 'active'
            GROUP BY e.id, e.name, e.tournament_type, e.category
            ORDER BY e.event_date, e.name
            """
        )
        activities = []
        for row in cursor.fetchall():
            event_id, name, tournament_type, category, match_count = row
            activities.append(
                {
                    "id": event_id,
                    "title": f"{name} Bracket",
                    "description": (
                        f"{tournament_type or category or 'Tournament'} · "
                        f"{match_count} bracket match{'es' if match_count != 1 else ''}"
                    ),
                    "activity_type": "bracket_scoring",
                    "icon": "account_tree",
                    "match_id": None,
                    "event_id": event_id,
                    "created_at": "",
                }
            )
        return activities


def fetch_bracket_match(match_id):
    with connection.cursor() as cursor:
        cursor.execute(
            _BRACKET_MATCH_SQL.replace(
                "WHERE e.status = 'active'",
                "WHERE e.status = 'active' AND bm.id = %s",
            ),
            [match_id],
        )
        rows = _rows_to_dicts(cursor)
    if not rows:
        return None
    return serialize_bracket_row(rows[0])


def update_bracket_match_score(match_id, score_a, score_b, status=None):
    bracket_status = APP_TO_BRACKET_STATUS.get(status, status) if status else None

    with connection.cursor() as cursor:
        if bracket_status:
            cursor.execute(
                """
                UPDATE events_bracketmatch
                SET score_a = %s, score_b = %s, status = %s, updated_at = NOW()
                WHERE id = %s
                """,
                [str(score_a), str(score_b), bracket_status, match_id],
            )
        else:
            cursor.execute(
                """
                UPDATE events_bracketmatch
                SET score_a = %s, score_b = %s, updated_at = NOW()
                WHERE id = %s
                """,
                [str(score_a), str(score_b), match_id],
            )

    return fetch_bracket_match(match_id)
