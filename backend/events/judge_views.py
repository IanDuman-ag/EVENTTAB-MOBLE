from datetime import datetime

from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from accounts.models import AccessCode

from .judge_data import (
    fetch_assignment_detail,
    fetch_judge_assignments,
    fetch_judge_dashboard,
    fetch_judge_profile,
    fetch_notification_count,
    fetch_score_history,
)


def _is_judge(user):
    if user.is_staff or user.is_superuser:
        return True
    if user.groups.filter(name__iexact="Judge").exists():
        return True
    return AccessCode.objects.filter(
        user=user,
        role="judge",
        is_active=True,
    ).exists()


def _parse_date(value):
    if not value:
        return None
    try:
        return datetime.strptime(value, "%Y-%m-%d").date()
    except ValueError:
        return None


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def judge_dashboard(request):
    """GET /api/events/judge/dashboard/"""
    if not _is_judge(request.user):
        return Response({"detail": "Judge access required."}, status=status.HTTP_403_FORBIDDEN)

    data = fetch_judge_dashboard(request.user)
    data["notification_count"] = fetch_notification_count(request.user)
    return Response(data)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def judge_assignments(request):
    """GET /api/events/judge/assignments/?status=upcoming|ongoing|completed"""
    if not _is_judge(request.user):
        return Response({"detail": "Judge access required."}, status=status.HTTP_403_FORBIDDEN)

    assignments = fetch_judge_assignments(request.user)
    status_filter = (request.query_params.get("status") or "").lower()
    if status_filter in ("upcoming", "ongoing", "completed"):
        assignments = [a for a in assignments if a["status"] == status_filter]

    counts = {"upcoming": 0, "ongoing": 0, "completed": 0}
    all_assignments = fetch_judge_assignments(request.user)
    for item in all_assignments:
        key = item.get("status")
        if key in counts:
            counts[key] += 1

    return Response(
        {
            "assignments": assignments,
            "counts": counts,
            "today_display": datetime.now().strftime("%b %d, %Y"),
        }
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def judge_assignment_detail(request, judging_event_id):
    """GET /api/events/judge/assignments/<id>/"""
    if not _is_judge(request.user):
        return Response({"detail": "Judge access required."}, status=status.HTTP_403_FORBIDDEN)

    detail = fetch_assignment_detail(request.user, judging_event_id)
    if detail is None:
        return Response({"detail": "Assignment not found."}, status=status.HTTP_404_NOT_FOUND)
    return Response(detail)


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def judge_score_history(request):
    """GET /api/events/judge/score-history/?status=all|pending|approved|rejected"""
    if not _is_judge(request.user):
        return Response({"detail": "Judge access required."}, status=status.HTTP_403_FORBIDDEN)

    status_filter = (request.query_params.get("status") or "all").lower()
    date_from = _parse_date(request.query_params.get("date_from"))
    date_to = _parse_date(request.query_params.get("date_to"))

    return Response(
        fetch_score_history(
            request.user,
            status_filter=status_filter,
            date_from=date_from,
            date_to=date_to,
        )
    )


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def judge_profile(request):
    """GET /api/events/judge/profile/"""
    if not _is_judge(request.user):
        return Response({"detail": "Judge access required."}, status=status.HTTP_403_FORBIDDEN)

    data = fetch_judge_profile(request.user)
    data["notification_count"] = fetch_notification_count(request.user)
    return Response(data)
