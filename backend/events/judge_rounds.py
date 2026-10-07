"""Resolve portal rounds without changing existing criteria or score records."""
import json
from decimal import Decimal

from django.db import connection
from rest_framework.exceptions import ValidationError

from .models import CandidateStageEligibility, Criterion


def _json_list(value):
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except (TypeError, ValueError):
            return []
    return value if isinstance(value, list) else []


def _json_rows(value):
    return [row for row in _json_list(value) if isinstance(row, dict)]


def _json_object(value):
    if isinstance(value, str):
        try:
            value = json.loads(value)
        except (TypeError, ValueError):
            return {}
    return value if isinstance(value, dict) else {}


def judging_rounds(event):
    criteria = list(Criterion.objects.filter(event=event).order_by("order", "id"))
    with connection.cursor() as cursor:
        cursor.execute(
            "SELECT rounds_config, judging_criteria_config, criteria_score_method, "
            "result_processing_config, judge_settings, deductions_enabled, "
            "deductions_config, participant_ids, id, status FROM events_event "
            "WHERE judging_event_id = %s ORDER BY id LIMIT 1",
            [event.id],
        )
        portal = cursor.fetchone()
    rounds = _json_rows(portal[0]) if portal else []
    config = _json_rows(portal[1]) if portal else []
    metadata = {}
    rules = {}
    if portal and len(portal) > 2:
        rules = {
            "method": portal[2] or "weighted_percentage",
            "results": _json_object(portal[3]),
            "judges": _json_object(portal[4]),
            "deductions": _json_rows(portal[6]) if portal[5] else [],
            "participant_ids": _json_list(portal[7]),
            "portal_event_id": portal[8],
            "event_completed": portal[9] == "completed",
        }
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT id, purpose, overall_weight_percent FROM events_eventscoringcategory "
                "WHERE event_id = %s ORDER BY display_order, id", [portal[8]],
            )
            categories = {str(cid): (purpose, weight) for cid, purpose, weight in cursor.fetchall()}
    else:
        categories = {}
    # Names and ordering are preserved by both portal and mobile sync. Never
    # assume a JSON criterion id is an ORM primary key.
    used_ids = set()
    for row in config:
        match = next((c for c in criteria if c.id not in used_ids
                      and c.name == str(row.get("name") or "")[:100]), None)
        if match:
            used_ids.add(match.id)
            metadata[match.id] = row
            category = categories.get(str(row.get("segment_id")))
            if category:
                metadata[match.id] = {
                    **row,
                    "effective_weight_percent": Decimal(str(match.weight_percent)) * Decimal(str(category[1])) / Decimal("100"),
                    "category_weight_percent": float(category[1]),
                    "is_official_criterion": category[0] == "official",
                }
    if rounds:
        result = []
        for index, row in enumerate(rounds):
            round_id = str(row.get("id") or row.get("stage_number") or row.get("name") or index + 1)
            ids = [c.id for c in criteria
                   if (not config or c.id in metadata)
                   if str(metadata.get(c.id, {}).get("round_id") or round_id) == round_id]
            result.append({
                "id": round_id, "stage_id": None,
                "name": row.get("name") or f"Round {index + 1}",
                "description": row.get("description") or "",
                "status": row.get("status") or ("open" if index == 0 else "locked"),
                "order": index, "is_active": row.get("status") == "open",
                "criteria_ids": ids,
                "weight_percent": row.get("weight", 100),
                "carry_previous_scores": row["score_handling"] == "carry" if row.get("score_handling") else bool(row.get("carry_previous_scores")),
                "is_final": bool(row.get("is_final")) or index == len(rounds) - 1,
                "tie_handling": row.get("tie_handling"),
                "rules": rules,
            })
        return result, metadata

    result = [{
        "id": str(stage.id), "stage_id": stage.id, "name": stage.name,
        "description": stage.description, "status": stage.status,
        "order": stage.order, "is_active": stage.is_active,
        "criteria_ids": [c.id for c in criteria if c.stage_id in (None, stage.id)],
        "weight_percent": float(stage.weight_percent),
        "carry_previous_scores": True, "rules": rules,
    } for stage in event.stages.all().order_by("order", "id")]
    if not result:
        result = [{
            "id": "main", "stage_id": None, "name": "Main Scoring",
            "description": event.description or "", "order": 0,
            "status": "open" if event.status == "active" else event.status,
            "is_active": True, "criteria_ids": [c.id for c in criteria],
        }]
    result[-1]["is_final"] = True
    return result, metadata


def select_judging_round(rounds, round_id=None):
    if round_id is not None:
        match = next((row for row in rounds if row["id"] == str(round_id)), None)
        if match is None:
            raise ValidationError({"round_id": "Round not found in this event."})
        return match
    return next((row for row in rounds if row.get("is_active")), rounds[0])


def round_is_open(event, round_data):
    return event.status == "active" and round_data["status"] in (
        "open", "scoring_open", "next_stage_open",
    )


def validate_round_scoring(event, candidate, round_data):
    if not round_is_open(event, round_data):
        raise ValidationError({"detail": "Scoring is not open for this round."})
    if not round_data["criteria_ids"]:
        raise ValidationError({"detail": "No criteria configured for this round."})
    if round_data.get("rules", {}).get("portal_event_id"):
        from .judge_results import eligible_candidates
        if not any(row.id == candidate.id for row in eligible_candidates(event, round_data)):
            raise ValidationError({"detail": "Participant is not qualified for this round."})
    stage_id = round_data.get("stage_id")
    if stage_id:
        eligibility = CandidateStageEligibility.objects.filter(stage_id=stage_id)
        if eligibility.exists() and not eligibility.filter(candidate=candidate, is_qualified=True).exists():
            raise ValidationError({"detail": "Participant is not qualified for this round."})
