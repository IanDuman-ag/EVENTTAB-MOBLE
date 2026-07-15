from rest_framework import viewsets, permissions
from rest_framework.decorators import action
from rest_framework.response import Response
from django.db import models, connection
from django.db.utils import ProgrammingError
from django.db.models import Sum, Q
from decimal import Decimal

from .models import Team, Match, Activity, EventCategory, JudgingEvent, Candidate, JudgeScore
from .serializers import (
    TeamSerializer, MatchSerializer, ActivitySerializer,
    EventCategorySerializer, JudgingEventSerializer, CandidateStandingSerializer,
)


class TeamViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/events/teams/                        — all teams
    GET /api/events/teams/{id}/                   — single team
    GET /api/events/teams/{id}/matches/           — recent matches for a team
    GET /api/events/teams/?updated_after=ISO      — teams changed since timestamp
    """
    queryset = Team.objects.all()
    serializer_class = TeamSerializer
    permission_classes = [permissions.AllowAny]

    def _absolute_logo(self, path):
        raw = (path or "").strip()
        if not raw:
            return ""
        if raw.startswith("http://") or raw.startswith("https://") or raw.startswith("data:"):
            return raw
        from django.conf import settings

        media_base = getattr(settings, "MEDIA_BASE_URL", "").rstrip("/")
        if not media_base:
            media_base = "/media"
        cleaned = raw.lstrip("/")
        if cleaned.startswith("media/"):
            cleaned = cleaned[len("media/") :]
        if media_base.startswith("http"):
            return f"{media_base}/{cleaned}"
        return f"/media/{cleaned}"

    def _teams_fallback_payload(self):
        """Portal DB schema differs from Django models — read real columns."""
        teams = []
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT t.id,
                       t.name,
                       COALESCE(NULLIF(t.code, ''), d.code, UPPER(LEFT(t.name, 4))),
                       COALESCE(NULLIF(d.delegation_color, ''), '#00C5D9'),
                       COALESCE(NULLIF(t.image, ''), NULLIF(d.logo, ''), ''),
                       COALESCE(NULLIF(t.members::text, ''), '0'),
                       COALESCE(
                           NULLIF(d.remarks, ''),
                           NULLIF(d.name, ''),
                           CONCAT('Representing ', t.name, '.')
                       ),
                       COALESCE(t.updated_at, t.created_at)
                FROM events_team t
                LEFT JOIN events_department d ON d.id = t.department_id
                ORDER BY t.name
                """
            )
            for row in cursor.fetchall():
                logo = self._absolute_logo(row[4] or "")
                motto = (row[6] or "").strip()
                try:
                    member_count = int(str(row[5] or "0").strip() or "0")
                except (TypeError, ValueError):
                    member_count = 0
                teams.append(
                    {
                        "id": row[0],
                        "name": row[1],
                        "abbreviation": (row[2] or "?")[:10].upper(),
                        "logo_icon": logo,
                        "color": row[3] or "#00C5D9",
                        "description": motto,
                        "member_count": member_count,
                        "updated_at": row[7].isoformat() if row[7] else None,
                    }
                )
        return teams

    def list(self, request, *args, **kwargs):
        try:
            return super().list(request, *args, **kwargs)
        except ProgrammingError:
            return Response(self._teams_fallback_payload())

    def retrieve(self, request, *args, **kwargs):
        try:
            return super().retrieve(request, *args, **kwargs)
        except ProgrammingError:
            team_id = kwargs.get("pk")
            for team in self._teams_fallback_payload():
                if str(team["id"]) == str(team_id):
                    return Response(team)
            return Response({"detail": "Not found."}, status=404)

    def get_queryset(self):
        qs = super().get_queryset()
        updated_after = self.request.query_params.get('updated_after')
        if updated_after:
            try:
                from django.utils.dateparse import parse_datetime
                dt = parse_datetime(updated_after)
                if dt:
                    qs = qs.filter(updated_at__gt=dt)
            except (ValueError, TypeError):
                pass
        return qs

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
    """
    GET /api/events/matches/                      — all matches
    GET /api/events/matches/{id}/                 — single match
    GET /api/events/matches/featured/             — featured match
    GET /api/events/matches/upcoming/             — upcoming matches
    GET /api/events/matches/?sport=basketball     — filter by sport
    GET /api/events/matches/?updated_after=ISO    — matches changed since timestamp
    GET /api/events/matches/?status=live          — filter by status
    """
    queryset = Match.objects.all()
    serializer_class = MatchSerializer
    permission_classes = [permissions.AllowAny]

    def get_queryset(self):
        qs = super().get_queryset()
        sport = self.request.query_params.get('sport')
        if sport and sport != 'all':
            qs = qs.filter(sport=sport)
        status = self.request.query_params.get('status')
        if status:
            qs = qs.filter(status=status)
        updated_after = self.request.query_params.get('updated_after')
        if updated_after:
            try:
                from django.utils.dateparse import parse_datetime
                dt = parse_datetime(updated_after)
                if dt:
                    qs = qs.filter(updated_at__gt=dt)
            except (ValueError, TypeError):
                pass
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
            # Official standings: only tabulator-approved judge scores.
            scores_qs = JudgeScore.objects.filter(
                candidate=candidate,
                approval_status="approved",
            )
            total = Decimal('0.00')
            for js in scores_qs.select_related('criterion'):
                total += js.score * js.criterion.weight_percent / Decimal('100')

            pending_live = JudgeScore.objects.filter(
                candidate=candidate,
                approval_status="pending",
                submitted_at__isnull=False,
            ).exists()

            results.append({
                'candidate_id': candidate.id,
                'name': candidate.name,
                'number': candidate.number,
                'total_score': total,
                'is_live': pending_live,
                'is_official': scores_qs.exists(),
            })

        # Public leaderboard shows official (approved) results only.
        results = [r for r in results if r['is_official']]
        results.sort(key=lambda x: x['total_score'], reverse=True)

        for i, r in enumerate(results):
            r['rank'] = i + 1

        serializer = CandidateStandingSerializer(results, many=True)
        return Response(serializer.data)
