"""Round calculations and the gate for publishing official event results."""
from collections import defaultdict
from decimal import Decimal

from django.contrib.auth import get_user_model
from django.db import connection
from rest_framework.exceptions import ValidationError

from .judge_rounds import judging_rounds
from .models import Candidate, CandidateStageEligibility, JudgeScore


def round_maximum(criteria, round_data, metadata=None):
    metadata = metadata or {}
    criteria = [c for c in criteria if metadata.get(c.id, {}).get("is_official_criterion", True)]
    method = round_data.get("rules", {}).get("method", "weighted_percentage")
    if method == "raw_score":
        return float(sum(c.max_score for c in criteria))
    if method == "average_score":
        return float(sum(c.max_score for c in criteria) / max(len(criteria), 1))
    return float(sum(Decimal(str(metadata.get(c.id, {}).get("effective_weight_percent", c.weight_percent))) for c in criteria))


def judge_round_progress(user, event, rounds):
    candidates = list(Candidate.objects.filter(event=event).order_by("number"))
    submitted = set(JudgeScore.objects.filter(
        judge=user, candidate__event=event, is_locked=True, is_draft=False,
    ).exclude(approval_status="rejected").values_list("candidate_id", "criterion_id"))
    progress = []
    for round_data in rounds:
        eligible = eligible_candidates(event, round_data, candidates)
        ids = round_data["criteria_ids"]
        scored = sum(bool(ids) and all((candidate.id, cid) in submitted for cid in ids) for candidate in eligible)
        progress.append({
            "round_id": round_data["id"], "name": round_data.get("name", "Round"),
            "total": len(eligible), "scored": scored,
            "complete": bool(eligible) and scored == len(eligible),
        })
    return progress


def eligible_candidates(event, round_data, candidates=None):
    candidates = list(candidates if candidates is not None else Candidate.objects.filter(event=event).order_by("number"))
    stage_id = round_data.get("stage_id")
    if stage_id:
        eligibility = list(CandidateStageEligibility.objects.filter(stage_id=stage_id).values_list("candidate_id", "is_qualified"))
        if eligibility:
            ids = {cid for cid, qualified in eligibility if qualified}
            return [candidate for candidate in candidates if candidate.id in ids]
    rules = round_data.get("rules", {})
    # The opening portal round starts with the event roster. Qualification
    # lists gate advancement into later rounds, not entry into the first.
    if rules.get("portal_event_id") and round_data.get("order", 0) == 0:
        return candidates
    qualified = rules.get("results", {}).get("qualified_participant_ids", {})
    selected = qualified.get(str(round_data.get("order", 0)))
    source_ids = rules.get("participant_ids", [])
    if selected is not None:
        # The mobile sync numbers candidates in the portal's selected order.
        # A changed roster cannot safely be mapped to old scored candidates.
        if len(source_ids) != len(candidates):
            return []
        selected_ids = {str(value) for value in selected}
        return [candidate for candidate in candidates
                if 0 < candidate.number <= len(source_ids)
                and str(source_ids[candidate.number - 1]) in selected_ids]
    return candidates


def round_score(scores, round_data, metadata=None):
    """Calculate one judge's recorded round using the saved scoring method."""
    metadata = metadata or {}
    scores = [score for score in scores if metadata.get(score.criterion_id, {}).get("is_official_criterion", True)]
    method = round_data.get("rules", {}).get("method", "weighted_percentage")
    if method == "raw_score":
        return sum((Decimal(str(score.score)) for score in scores), Decimal("0"))
    if method == "average_score":
        return sum((Decimal(str(score.score)) for score in scores), Decimal("0")) / max(len(scores), 1)
    if method != "weighted_percentage":
        raise ValidationError({"detail": "Unsupported event scoring method. Review the event configuration."})
    total = Decimal("0")
    for score in scores:
        criterion = score.criterion
        weight = Decimal(str(metadata.get(criterion.id, {}).get("effective_weight_percent", criterion.weight_percent)))
        if criterion.max_score > 0:
            total += Decimal(str(score.score)) * weight / criterion.max_score
    return total


def _required_judges(event, rules):
    portal_id = rules.get("portal_event_id")
    if portal_id:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT u.username FROM events_event_assigned_judges ej "
                "JOIN auth_user u ON u.id = ej.user_id WHERE ej.event_id = %s", [portal_id],
            )
            names = {row[0] for row in cursor.fetchall()}
        users = dict(get_user_model().objects.filter(username__in=names, is_active=True).values_list("username", "id"))
        # Missing mobile identities still count as judges who have not submitted.
        return {users.get(name) for name in names}
    return set(event.assigned_judges.filter(is_active=True).values_list("id", flat=True))


def _result_rounds(rounds, rules):
    basis = rules.get("results", {}).get("final_result_basis")
    if basis == "manual_authorized":
        return [], basis
    if basis in ("weighted_rounds", "cumulative_rounds"):
        return rounds, basis
    if basis == "final_round_only":
        return [rounds[-1]], basis
    if basis not in (None, "main_round"):
        return [], basis
    # ORM stages specify weights. Portal main-round rules explicitly choose
    # whether to start at zero or carry earlier scores into the last round.
    if not rules.get("portal_event_id") and len(rounds) > 1:
        return rounds, "weighted_rounds"
    start = len(rounds) - 1
    while start > 0 and rounds[start].get("carry_previous_scores"):
        start -= 1
    return rounds[start:], "cumulative_rounds" if start < len(rounds) - 1 else "final_round_only"


def official_event_results(event, rounds=None, metadata=None):
    """No partial multi-round result or winner is exposed by this function."""
    if rounds is None:
        rounds, metadata = judging_rounds(event)
    metadata = metadata or {}
    rules = rounds[-1].get("rules", {})
    multi_round = len(rounds) > 1
    result_rules = rules.get("results", {})
    if result_rules.get("auto_calculate_final") is False or result_rules.get("auto_generate_rankings") is False:
        return []
    if multi_round and not (
        rounds[-1].get("status") == "completed"
        or event.status == "completed" or rules.get("event_completed")
    ):
        return []
    selected_rounds, basis = _result_rounds(rounds, rules)
    if not selected_rounds:
        return []
    candidates = list(Candidate.objects.filter(event=event).order_by("number"))
    finalists = eligible_candidates(event, rounds[-1], candidates) if multi_round else candidates
    if not finalists:
        return []
    approved = list(JudgeScore.objects.filter(
        candidate__event=event, approval_status="approved", is_locked=True, is_draft=False,
    ).select_related("criterion"))
    by_candidate = defaultdict(lambda: defaultdict(dict))
    for score in approved:
        by_candidate[score.candidate_id][score.judge_id][score.criterion_id] = score
    judges = _required_judges(event, rules) if multi_round else set()
    require_all = rules.get("judges", {}).get("require_all_judges", True)
    if multi_round and (not judges or (require_all and None in judges)):
        return []
    results = []
    for candidate in finalists:
        per_round = []
        for round_data in selected_rounds:
            ids = set(round_data["criteria_ids"])
            totals = []
            candidate_scores = by_candidate[candidate.id]
            judging_ids = (judges if require_all else judges.intersection(candidate_scores)) if multi_round else set(candidate_scores)
            for judge_id in judging_ids:
                scores = candidate_scores.get(judge_id, {})
                if multi_round and (not ids or not ids.issubset(scores)):
                    if require_all:
                        return []
                    continue
                recorded = [score for cid, score in scores.items() if cid in ids]
                if recorded:
                    totals.append(round_score(recorded, round_data, metadata))
            if not totals:
                if multi_round:
                    return []
                continue
            if rules.get("judges", {}).get("remove_high_low") and len(totals) > 2:
                totals = sorted(totals)[1:-1]
            per_round.append({
                "round_id": round_data["id"], "name": round_data.get("name", "Round"),
                "score": sum(totals) / len(totals),
                "weight": Decimal(str(round_data.get("weight_percent", 100))),
            })
        if not per_round:
            continue
        if basis == "weighted_rounds":
            weight = sum(row["weight"] for row in per_round)
            if weight <= 0:
                return []
            total = sum(row["score"] * row["weight"] for row in per_round) / weight
        else:
            total = sum(row["score"] for row in per_round)
        deduction = Decimal("0")
        for row in rules.get("deductions", []):
            value = Decimal(str(row.get("value") or 0))
            deduction += total * value / 100 if row.get("deduction_type") == "percentage" else value
        total = max(Decimal("0"), total - deduction)
        results.append({
            "candidate_id": candidate.id, "name": candidate.name, "number": candidate.number,
            "department": candidate.department or "", "total_score": total.quantize(Decimal("0.01")),
            "is_live": False, "is_official": True, "result_scope": "event",
            "round_scores": [{"round_id": row["round_id"], "name": row["name"], "score": float(row["score"])} for row in per_round],
        })
    results.sort(key=lambda row: (-row["total_score"], row["number"]))
    manual_ties = rounds[-1].get("tie_handling") == "manual_decision" or result_rules.get("stage_tiebreak_method") == "manual_decision"
    if manual_ties and len({row["total_score"] for row in results}) != len(results):
        return []
    for index, row in enumerate(results):
        row["rank"] = results[index - 1]["rank"] if index and row["total_score"] == results[index - 1]["total_score"] else index + 1
    return results
