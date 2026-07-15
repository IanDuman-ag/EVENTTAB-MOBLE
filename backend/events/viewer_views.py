from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .viewer_data import (
    fetch_viewer_dashboard,
    fetch_viewer_events,
    fetch_viewer_live,
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
    """GET /api/events/viewer/events/?status=&category=&q="""
    return Response(
        fetch_viewer_events(
            status_filter=request.query_params.get("status"),
            category_filter=request.query_params.get("category"),
            search=request.query_params.get("q"),
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
