"""Tabulator review queue — pending scorer + judge submissions."""

from collections import defaultdict
from decimal import Decimal

from django.db.models import Max
from django.utils import timezone

from .bracket_data import fetch_bracket_match, update_bracket_match_score
from .models import BracketScorerSubmission, JudgeScore, ScorerSubmission


def _weighted_total(scores_qs):
    total = Decimal("0")
    for js in scores_qs:
        if js.criterion.max_score > 0:
            total += js.score * js.criterion.weight_percent / js.criterion.max_score
    return float(round(total, 1))


def fetch_pending_queue():
    """Combined pending list for the tabulator portal."""
    items = []

    # Scorer bracket submissions
    for sub in BracketScorerSubmission.objects.filter(
        approval_status="pending"
    ).select_related("scorer").order_by("-submitted_at"):
        match = fetch_bracket_match(sub.bracket_match_id) or {}
        items.append(
            {
                "id": f"scorer-bracket-{sub.id}",
                "kind": "scorer",
                "source": "bracket",
                "submission_id": sub.id,
                "title": match.get("match_title")
                or match.get("title")
                or f"Bracket match #{sub.bracket_match_id}",
                "subtitle": match.get("teams_label") or "",
                "event_name": match.get("event_name") or "",
                "venue": match.get("venue") or "",
                "score_display": f"{sub.score_a} - {sub.score_b}",
                "score_a": sub.score_a,
                "score_b": sub.score_b,
                "submitted_by": sub.scorer.get_full_name()
                or sub.scorer.username,
                "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
                "status": sub.approval_status,
            }
        )

    # Legacy scorer submissions
    for sub in ScorerSubmission.objects.filter(
        approval_status="pending"
    ).select_related("scorer", "match").order_by("-submitted_at"):
        m = sub.match
        items.append(
            {
                "id": f"scorer-legacy-{sub.id}",
                "kind": "scorer",
                "source": "legacy",
                "submission_id": sub.id,
                "title": m.title,
                "subtitle": m.title or f"Match #{m.id}",
                "event_name": m.title,
                "venue": m.venue or "",
                "score_display": f"{sub.score_a} - {sub.score_b}",
                "score_a": sub.score_a,
                "score_b": sub.score_b,
                "submitted_by": sub.scorer.get_full_name() or sub.scorer.username,
                "submitted_at": sub.submitted_at.isoformat() if sub.submitted_at else None,
                "status": sub.approval_status,
            }
        )

    # Judge submissions grouped by (judge, candidate)
    pending_scores = (
        JudgeScore.objects.filter(
            approval_status="pending",
            submitted_at__isnull=False,
        )
        .select_related("judge", "candidate", "candidate__event", "criterion")
        .order_by("-submitted_at")
    )
    groups = defaultdict(list)
    for js in pending_scores:
        groups[(js.judge_id, js.candidate_id)].append(js)

    for (judge_id, candidate_id), scores in groups.items():
        sample = scores[0]
        qs = JudgeScore.objects.filter(
            judge_id=judge_id,
            candidate_id=candidate_id,
            approval_status="pending",
        ).select_related("criterion")
        items.append(
            {
                "id": f"judge-{judge_id}-{candidate_id}",
                "kind": "judge",
                "source": "criteria",
                "judge_id": judge_id,
                "candidate_id": candidate_id,
                "judging_event_id": sample.candidate.event_id,
                "title": sample.candidate.event.title,
                "subtitle": f"#{sample.candidate.number} – {sample.candidate.name}",
                "event_name": sample.candidate.event.title,
                "venue": sample.candidate.event.venue or "",
                "score_display": f"{_weighted_total(qs)} / 100",
                "criteria_count": qs.count(),
                "submitted_by": sample.judge.get_full_name() or sample.judge.username,
                "submitted_at": (
                    qs.aggregate(latest=Max("submitted_at"))["latest"].isoformat()
                    if qs.aggregate(latest=Max("submitted_at"))["latest"]
                    else None
                ),
                "status": "pending",
            }
        )

    items.sort(key=lambda x: x.get("submitted_at") or "", reverse=True)
    return {
        "items": items,
        "counts": {
            "pending": len(items),
            "scorer": sum(1 for i in items if i["kind"] == "scorer"),
            "judge": sum(1 for i in items if i["kind"] == "judge"),
        },
    }


def review_scorer_bracket(submission_id, decision, note=""):
    """decision: approved | returned"""
    sub = BracketScorerSubmission.objects.get(pk=submission_id)
    if decision not in ("approved", "returned"):
        raise ValueError("decision must be approved or returned")

    sub.approval_status = decision
    sub.save(update_fields=["approval_status", "submitted_at"])

    if decision == "returned":
        # Unlock match so scorer can resubmit.
        match = fetch_bracket_match(sub.bracket_match_id)
        if match and match.get("status") == "completed":
            update_bracket_match_score(
                sub.bracket_match_id,
                sub.score_a,
                sub.score_b,
                status="live",
            )
            sub.match_status = "live"
            sub.save(update_fields=["match_status", "submitted_at"])

    return {
        "id": sub.id,
        "kind": "scorer",
        "source": "bracket",
        "approval_status": sub.approval_status,
        "note": note,
    }


def review_scorer_legacy(submission_id, decision, note=""):
    sub = ScorerSubmission.objects.select_related("match").get(pk=submission_id)
    if decision == "returned":
        # Legacy model has no returned — map to pending unlock.
        sub.approval_status = "pending"
        if sub.match.status == "completed":
            sub.match.status = "live"
            sub.match.save(update_fields=["status"])
            sub.match_status = "live"
        sub.save(update_fields=["approval_status", "match_status", "submitted_at"])
        status_out = "returned"
    elif decision == "approved":
        sub.approval_status = "approved"
        sub.save(update_fields=["approval_status", "submitted_at"])
        status_out = "approved"
    else:
        raise ValueError("decision must be approved or returned")

    return {
        "id": sub.id,
        "kind": "scorer",
        "source": "legacy",
        "approval_status": status_out,
        "note": note,
    }


def review_judge_scores(judge_id, candidate_id, decision, note=""):
    """decision: approved | rejected"""
    if decision not in ("approved", "rejected"):
        raise ValueError("decision must be approved or rejected")

    qs = JudgeScore.objects.filter(
        judge_id=judge_id,
        candidate_id=candidate_id,
        submitted_at__isnull=False,
    )
    if not qs.exists():
        raise JudgeScore.DoesNotExist("No submitted scores found.")

    now = timezone.now()
    if decision == "approved":
        qs.update(
            approval_status="approved",
            is_locked=True,
            reviewed_at=now,
            review_note=note or "",
        )
    else:
        # Rejected: unlock so judge can resubmit.
        qs.update(
            approval_status="rejected",
            is_locked=False,
            reviewed_at=now,
            review_note=note or "",
        )

    return {
        "kind": "judge",
        "judge_id": judge_id,
        "candidate_id": candidate_id,
        "approval_status": decision,
        "note": note,
    }


def approved_bracket_match_ids():
    return set(
        BracketScorerSubmission.objects.filter(
            approval_status="approved"
        ).values_list("bracket_match_id", flat=True)
    )


def approved_legacy_match_ids():
    return set(
        ScorerSubmission.objects.filter(
            approval_status="approved"
        ).values_list("match_id", flat=True)
    )
