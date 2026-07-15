"""Tabulator API — review pending scorer and judge score submissions."""

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.models import AccessCode

from .models import BracketScorerSubmission, JudgeScore, ScorerSubmission
from .tabulator_data import (
    fetch_pending_queue,
    review_judge_scores,
    review_scorer_bracket,
    review_scorer_legacy,
)


def _is_tabulator(user):
    if not user or not user.is_authenticated:
        return False
    if user.is_staff or user.is_superuser:
        return True
    if user.groups.filter(name="Tabulator").exists():
        return True
    return AccessCode.objects.filter(
        user=user,
        role="tabulator",
        is_active=True,
    ).exists()


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def tabulator_queue(request):
    """GET /api/events/tabulator/queue/"""
    if not _is_tabulator(request.user):
        return Response({"detail": "Tabulator access required."}, status=status.HTTP_403_FORBIDDEN)
    return Response(fetch_pending_queue())


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def tabulator_review(request):
    """
    POST /api/events/tabulator/review/
    Body examples:
      { "kind": "scorer", "source": "bracket", "submission_id": 1, "decision": "approved" }
      { "kind": "scorer", "source": "legacy", "submission_id": 1, "decision": "returned" }
      { "kind": "judge", "judge_id": 2, "candidate_id": 5, "decision": "approved" }
      { "kind": "judge", "judge_id": 2, "candidate_id": 5, "decision": "rejected" }
    """
    if not _is_tabulator(request.user):
        return Response({"detail": "Tabulator access required."}, status=status.HTTP_403_FORBIDDEN)

    kind = (request.data.get("kind") or "").lower()
    decision = (request.data.get("decision") or "").lower()
    note = request.data.get("note") or ""

    try:
        if kind == "scorer":
            source = (request.data.get("source") or "bracket").lower()
            submission_id = request.data.get("submission_id")
            if submission_id is None:
                return Response(
                    {"detail": "submission_id is required."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            if source == "legacy":
                result = review_scorer_legacy(int(submission_id), decision, note)
            else:
                result = review_scorer_bracket(int(submission_id), decision, note)
            return Response(result)

        if kind == "judge":
            judge_id = request.data.get("judge_id")
            candidate_id = request.data.get("candidate_id")
            if judge_id is None or candidate_id is None:
                return Response(
                    {"detail": "judge_id and candidate_id are required."},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            result = review_judge_scores(int(judge_id), int(candidate_id), decision, note)
            return Response(result)

        return Response({"detail": "kind must be scorer or judge."}, status=status.HTTP_400_BAD_REQUEST)
    except (BracketScorerSubmission.DoesNotExist, ScorerSubmission.DoesNotExist, JudgeScore.DoesNotExist):
        return Response({"detail": "Submission not found."}, status=status.HTTP_404_NOT_FOUND)
    except ValueError as exc:
        return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
    except Exception as exc:  # pragma: no cover
        return Response({"detail": str(exc)}, status=status.HTTP_400_BAD_REQUEST)
