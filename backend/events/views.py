from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import models
from django.db.models import Sum, Q
from decimal import Decimal

from .models import Team, Match, Activity, EventCategory, JudgingEvent, Candidate, JudgeScore
from .serializers import (
    TeamSerializer, MatchSerializer, ActivitySerializer,
    EventCategorySerializer, JudgingEventSerializer, CandidateStandingSerializer,
)


class TeamViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for viewing teams — public, no auth required"""
    queryset = Team.objects.all()
    serializer_class = TeamSerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=True, methods=['get'])
    def matches(self, request, pk=None):
        """GET /api/events/teams/{id}/matches/ — recent matches for a team"""
        team = self.get_object()
        qs = Match.objects.filter(
            Q(team_a=team) | Q(team_b=team)
        ).order_by('-scheduled_time')[:10]
        serializer = MatchSerializer(qs, many=True)
        return Response(serializer.data)


class MatchViewSet(viewsets.ReadOnlyModelViewSet):
    """API endpoint for viewing matches — public, no auth required"""
    queryset = Match.objects.all()
    serializer_class = MatchSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        sport = self.request.query_params.get('sport')
        if sport and sport != 'all':
            qs = qs.filter(sport=sport)
        return qs

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
    """API endpoint for viewing activity feed — public, no auth required"""
    queryset = Activity.objects.all()
    serializer_class = ActivitySerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        """Return recent activities (last 50)"""
        return Activity.objects.all()[:50]


# ---------------------------------------------------------------------------
# Rankings API — used by the viewer Rankings page
# Registered as /api/events/rankings-events/ to avoid clash with judging_views
# ---------------------------------------------------------------------------

class JudgingEventViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/events/rankings-events/                  — list all events
    GET /api/events/rankings-events/{id}/             — single event detail
    GET /api/events/rankings-events/{id}/standings/   — ranked candidates
    Public — no auth required for viewer rankings.
    """
    queryset = JudgingEvent.objects.select_related('category').all()
    serializer_class = JudgingEventSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        category_id = self.request.query_params.get('category')
        if category_id:
            qs = qs.filter(category_id=category_id)
        return qs

    @action(detail=True, methods=['get'])
    def standings(self, request, pk=None):
        """
        Return candidates ranked by their total weighted score.
        Each candidate's total = sum of (score * criterion.weight_percent / 100)
        across all judges and criteria.
        """
        event = self.get_object()
        candidates = Candidate.objects.filter(event=event)

        results = []
        for candidate in candidates:
            scores_qs = JudgeScore.objects.filter(candidate=candidate)
            total = Decimal('0.00')
            for js in scores_qs.select_related('criterion'):
                total += js.score * js.criterion.weight_percent / Decimal('100')

            is_live = scores_qs.filter(is_locked=False, submitted_at__isnull=False).exists()

            results.append({
                'candidate_id': candidate.id,
                'name': candidate.name,
                'number': candidate.number,
                'total_score': total,
                'is_live': is_live,
            })

        results.sort(key=lambda x: x['total_score'], reverse=True)

        for i, r in enumerate(results):
            r['rank'] = i + 1

        serializer = CandidateStandingSerializer(results, many=True)
        return Response(serializer.data)
