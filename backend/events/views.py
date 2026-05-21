from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Team, Match, Activity
from .serializers import TeamSerializer, MatchSerializer, ActivitySerializer


class TeamViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for viewing teams"""
    queryset = Team.objects.all()
    serializer_class = TeamSerializer
    permission_classes = [permissions.IsAuthenticated]


class MatchViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for viewing matches"""
    queryset = Match.objects.all()
    serializer_class = MatchSerializer
    permission_classes = [permissions.IsAuthenticated]
    
    @action(detail=False, methods=['get'])
    def featured(self, request):
        """Get the featured match"""
        featured_match = Match.objects.filter(is_featured=True).first()
        if featured_match:
            serializer = self.get_serializer(featured_match)
            return Response(serializer.data)
        return Response(None)
    
    @action(detail=False, methods=['get'])
    def upcoming(self, request):
        """Get upcoming matches"""
        upcoming_matches = Match.objects.filter(status='upcoming').order_by('scheduled_time')[:10]
        serializer = self.get_serializer(upcoming_matches, many=True)
        return Response(serializer.data)


class ActivityViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for viewing activity feed"""
    queryset = Activity.objects.all()
    serializer_class = ActivitySerializer
    permission_classes = [permissions.IsAuthenticated]
    
    def get_queryset(self):
        """Return recent activities (last 50)"""
        return Activity.objects.all()[:50]
