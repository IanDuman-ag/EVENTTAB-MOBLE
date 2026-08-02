from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .viewer_data import (
    fetch_viewer_about,
    fetch_viewer_announcements,
    fetch_viewer_bracket,
    fetch_viewer_criteria_event_detail,
    fetch_viewer_dashboard,
    fetch_viewer_events,
    fetch_viewer_live,
    fetch_viewer_match_event_detail,
    fetch_viewer_notifications,
    fetch_viewer_profile,
    fetch_viewer_rankings,
)


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_dashboard(request):
    """GET /api/events/viewer/dashboard/"""
    return Response(fetch_viewer_dashboard())


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_events(request):
    """GET /api/events/viewer/events/?status=&category=&q=&type=match|criteria"""
    return Response(
        fetch_viewer_events(
            status_filter=request.query_params.get("status"),
            category_filter=request.query_params.get("category"),
            search=request.query_params.get("q"),
            event_type=request.query_params.get("type"),
        )
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_live(request):
    """GET /api/events/viewer/live/?sport="""
    return Response(
        fetch_viewer_live(sport_filter=request.query_params.get("sport"))
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_rankings(request):
    """GET /api/events/viewer/rankings/?sport=&category="""
    return Response(
        fetch_viewer_rankings(
            sport_filter=request.query_params.get("sport"),
            category_filter=request.query_params.get("category"),
        )
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_profile(request):
    """GET /api/events/viewer/profile/"""
    return Response(fetch_viewer_profile())


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_announcements(request):
    """GET /api/events/viewer/announcements/"""
    return Response({"announcements": fetch_viewer_announcements()})


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_notifications(request):
    """GET /api/events/viewer/notifications/"""
    notes = fetch_viewer_notifications()
    return Response(
        {
            "notifications": notes,
            "unread_count": sum(1 for n in notes if n.get("is_unread")),
        }
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_about(request):
    """GET /api/events/viewer/about/"""
    return Response(fetch_viewer_about())


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_bracket(request):
    """GET /api/events/viewer/bracket/?event_id="""
    event_id = request.query_params.get("event_id")
    return Response(
        fetch_viewer_bracket(int(event_id) if event_id else None)
    )


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_match_event_detail(request, match_id):
    """GET /api/events/viewer/match-events/<id>/"""
    data = fetch_viewer_match_event_detail(match_id)
    if data is None:
        return Response({"detail": "Not found."}, status=404)
    return Response(data)


@api_view(["GET"])
@permission_classes([AllowAny])
def viewer_criteria_event_detail(request, judging_event_id):
    """GET /api/events/viewer/criteria-events/<id>/"""
    data = fetch_viewer_criteria_event_detail(judging_event_id)
    if data is None:
        return Response({"detail": "Not found."}, status=404)
    return Response(data)
