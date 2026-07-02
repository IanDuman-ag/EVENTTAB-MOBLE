from rest_framework import serializers, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.models import AccessCode

from .bracket_data import fetch_bracket_events, fetch_bracket_match, update_bracket_match_score
from .models import BracketScorerSubmission, Match, ScorerSubmission
from .scorer_data import (
    fetch_scorer_assigned_event_ids,
    fetch_scorer_assignments,
    fetch_scorer_dashboard,
    fetch_scorer_history_entries,
    fetch_scorer_match_detail,
    fetch_scorer_matches,
    fetch_scorer_profile,
    record_bracket_submission,
)
from .serializers import MatchSerializer


def _is_scorer(user):
    if user.is_staff or user.is_superuser:
        return True
    if user.groups.filter(name__iexact="Scorer").exists():
        return True
    return AccessCode.objects.filter(
        user=user,
        role="scorer",
        is_active=True,
    ).exists()


class UpdateMatchScoreSerializer(serializers.Serializer):
    score_a = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    score_b = serializers.IntegerField(min_value=0, required=False, allow_null=True)
    status = serializers.ChoiceField(
        choices=["upcoming", "live", "completed", "cancelled"],
        required=False,
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_dashboard(request):
    """GET /api/events/scorer/dashboard/"""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    return Response(fetch_scorer_dashboard(request.user))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_assignments(request):
    """GET /api/events/scorer/assignments/?status=all|live|upcoming|completed"""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    status_filter = (request.query_params.get("status") or "all").lower()
    if status_filter == "all":
        status_filter = None
    return Response(fetch_scorer_assignments(request.user, status_filter=status_filter))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_profile(request):
    """GET /api/events/scorer/profile/"""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    return Response(fetch_scorer_profile(request.user))


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_bracket(request):
    """GET /api/events/scorer/bracket/ — tournament bracket progression."""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    from .scorer_data import fetch_scorer_assigned_event_ids

    event_ids = set(fetch_scorer_assigned_event_ids(request.user))
    events = [e for e in fetch_bracket_events() if e["event_id"] in event_ids]
    return Response({"events": events})


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_history(request):
    """GET /api/events/scorer/history/?status=all|pending|approved|returned&q="""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    status_filter = (request.query_params.get("status") or "all").lower()
    search = request.query_params.get("q") or request.query_params.get("search")
    return Response(
        fetch_scorer_history_entries(
            request.user,
            status_filter=status_filter,
            search=search,
        )
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_matches(request):
    """GET /api/events/scorer/matches/ — assigned live and upcoming bracket matches."""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    matches = fetch_scorer_matches(request.user)
    return Response([m for m in matches if m["status"] in ("live", "upcoming")])


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def scorer_match_detail(request, match_id):
    """GET /api/events/scorer/bracket/matches/<id>/ — single assigned match."""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    detail = fetch_scorer_match_detail(request.user, match_id)
    if detail is None:
        return Response({"detail": "Match not found."}, status=status.HTTP_404_NOT_FOUND)
    return Response(detail)


@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def scorer_update_bracket_score(request, match_id):
    """PATCH /api/events/scorer/bracket/matches/{id}/score/"""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    serializer = UpdateMatchScoreSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data
    if "score_a" not in data or "score_b" not in data:
        return Response(
            {"detail": "score_a and score_b are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    existing = fetch_bracket_match(match_id)
    if existing is None:
        return Response({"detail": "Bracket match not found."}, status=status.HTTP_404_NOT_FOUND)

    if existing.get("status") == "completed":
        return Response(
            {"detail": "Final score already submitted. Scores are locked."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if BracketScorerSubmission.objects.filter(
        bracket_match_id=match_id,
        scorer=request.user,
        match_status="completed",
    ).exists():
        return Response(
            {"detail": "You already submitted the final score for this match."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if existing.get("event_id") not in fetch_scorer_assigned_event_ids(request.user):
        return Response({"detail": "Match not assigned to you."}, status=status.HTTP_403_FORBIDDEN)

    status_value = data.get("status")
    if not status_value and existing["status"] == "upcoming":
        status_value = "live"

    updated = update_bracket_match_score(
        match_id,
        data["score_a"],
        data["score_b"],
        status=status_value,
    )
    record_bracket_submission(
        request.user,
        updated,
        data["score_a"],
        data["score_b"],
        status_value or updated.get("status"),
    )
    return Response(updated)


@api_view(["PATCH"])
@permission_classes([IsAuthenticated])
def scorer_update_score(request, match_id):
    """PATCH /api/events/scorer/matches/{id}/score/ — legacy match table."""
    if not _is_scorer(request.user):
        return Response({"detail": "Scorer access required."}, status=status.HTTP_403_FORBIDDEN)

    if fetch_bracket_match(match_id) is not None:
        return scorer_update_bracket_score(request, match_id)

    try:
        match = Match.objects.select_related("team_a", "team_b").get(pk=match_id)
    except Match.DoesNotExist:
        return Response({"detail": "Match not found."}, status=status.HTTP_404_NOT_FOUND)

    if match.status == "completed":
        return Response(
            {"detail": "Final score already submitted. Scores are locked."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    serializer = UpdateMatchScoreSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    data = serializer.validated_data
    score_changed = False

    if "score_a" in data:
        match.score_a = data["score_a"]
        score_changed = True
    if "score_b" in data:
        match.score_b = data["score_b"]
        score_changed = True
    if "status" in data:
        match.status = data["status"]
    elif score_changed and match.status == "upcoming":
        match.status = "live"

    match.save()

    if score_changed:
        ScorerSubmission.objects.update_or_create(
            match=match,
            scorer=request.user,
            defaults={
                "score_a": match.score_a or 0,
                "score_b": match.score_b or 0,
                "match_status": match.status,
                "approval_status": "pending",
            },
        )

    return Response(MatchSerializer(match).data)
