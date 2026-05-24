import uuid
from decimal import Decimal
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore
from .judging_serializers import (
    EventCategorySerializer, JudgingEventListSerializer,
    JudgingEventDetailSerializer, JudgeScoreSerializer, SubmitScoresSerializer
)
from .serializers import CandidateStandingSerializer


# ---------------------------------------------------------------------------
# Notifications — derived from real data, no separate model needed
# GET /api/events/judge-notifications/
# ---------------------------------------------------------------------------

@api_view(['GET'])
@permission_classes([permissions.IsAuthenticated])
def judge_notifications(request):
    """
    Returns a list of notifications for the authenticated judge, derived from:
    - Events they are assigned to (most recent first)
    - Scores they have locked (most recent first)
    """
    user = request.user
    notifications = []

    # Assigned events
    assigned = JudgingEvent.objects.filter(
        assigned_judges=user
    ).select_related('category').order_by('-date', '-time')[:10]

    for event in assigned:
        if event.status == 'active':
            icon = 'rocket_launch'
            title = 'Event is Live'
            body = f'"{event.title}" is currently active. Start scoring now.'
        else:
            icon = 'event_available'
            title = 'Event Assigned'
            body = f'You have been assigned to judge "{event.title}".'

        notifications.append({
            'id': f'event_{event.id}',
            'icon': icon,
            'icon_color': '#0D7A62',
            'title': title,
            'body': body,
            'time': event.date.isoformat(),
            'is_unread': event.status == 'active',
        })

    # Locked scores (most recent submissions)
    locked_scores = JudgeScore.objects.filter(
        judge=user, is_locked=True
    ).select_related('candidate', 'candidate__event').order_by('-submitted_at')

    seen_candidates = set()
    for js in locked_scores:
        key = (js.candidate_id, js.candidate.event_id)
        if key in seen_candidates:
            continue
        seen_candidates.add(key)

        notifications.append({
            'id': f'score_{js.candidate_id}_{js.candidate.event_id}',
            'icon': 'lock',
            'icon_color': '#9F66FF',
            'title': 'Score Locked',
            'body': f'Your scores for {js.candidate.name} in "{js.candidate.event.title}" have been locked.',
            'time': js.submitted_at.isoformat() if js.submitted_at else '',
            'is_unread': False,
        })

        if len(seen_candidates) >= 5:
            break

    # Sort: unread first, then by time descending
    notifications.sort(key=lambda n: (not n['is_unread'], n['time']), reverse=False)

    return Response(notifications[:20])

class EventCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/events/categories/              — list all categories (with event_count)
    GET /api/events/categories/{id}/         — single category
    GET /api/events/categories/{id}/events/  — events in this category
    Public — no auth required for viewer rankings.
    """
    queryset = EventCategory.objects.all()
    serializer_class = EventCategorySerializer
    permission_classes = [permissions.AllowAny]

    @action(detail=True, methods=['get'])
    def events(self, request, pk=None):
        category = self.get_object()
        events = category.events.all()
        serializer = JudgingEventListSerializer(events, many=True)
        return Response(serializer.data)


class JudgingEventViewSet(viewsets.ReadOnlyModelViewSet):
    """
    GET /api/events/judging-events/                        — list all events
    GET /api/events/judging-events/{id}/                   — detail with criteria + candidates
    GET /api/events/judging-events/{id}/standings/         — ranked candidates by score
    GET /api/events/judging-events/{id}/my_scores/?candidate_id=X — judge's own scores
    POST /api/events/judging-events/{id}/submit_scores/    — submit + lock scores
    """
    queryset = JudgingEvent.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return JudgingEventDetailSerializer
        return JudgingEventListSerializer

    # ── Standings (used by Rankings page) ────────────────────────────────────
    @action(detail=True, methods=['get'])
    def standings(self, request, pk=None):
        """
        Return candidates ranked by their total weighted score.
        Formula: sum(score * weight_percent / max_score) across all judges and criteria.
        """
        event = self.get_object()
        candidates = Candidate.objects.filter(event=event)

        results = []
        for candidate in candidates:
            scores_qs = JudgeScore.objects.filter(candidate=candidate).select_related('criterion')
            total = Decimal('0.00')
            for js in scores_qs:
                if js.criterion.max_score > 0:
                    total += js.score * js.criterion.weight_percent / js.criterion.max_score
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

    # ── Submit scores (locks permanently) ────────────────────────────────────
    @action(detail=True, methods=['post'])
    def submit_scores(self, request, pk=None):
        event = self.get_object()
        serializer = SubmitScoresSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        candidate_id = serializer.validated_data['candidate_id']
        scores_data = serializer.validated_data['scores']

        try:
            candidate = Candidate.objects.get(id=candidate_id, event=event)
        except Candidate.DoesNotExist:
            return Response({'detail': 'Candidate not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Prevent re-submission
        if JudgeScore.objects.filter(judge=request.user, candidate=candidate, is_locked=True).exists():
            return Response({'detail': 'Scores already submitted and locked.'}, status=status.HTTP_400_BAD_REQUEST)

        verification_id = str(uuid.uuid4())[:13].upper()
        submitted_at = timezone.now()
        created_scores = []

        for score_item in scores_data:
            criterion_id = score_item['criterion_id']
            score_value = float(score_item['score'])

            try:
                criterion = Criterion.objects.get(id=criterion_id, event=event)
            except Criterion.DoesNotExist:
                continue

            score_value = min(max(score_value, 0), float(criterion.max_score))

            judge_score, _ = JudgeScore.objects.update_or_create(
                judge=request.user,
                candidate=candidate,
                criterion=criterion,
                defaults={
                    'score': score_value,
                    'is_locked': True,
                    'submitted_at': submitted_at,
                    'verification_id': verification_id,
                }
            )
            created_scores.append(judge_score)

        # Build response with weighted breakdown
        total_score = 0
        breakdown = []
        for js in created_scores:
            weighted = float(js.score) * float(js.criterion.weight_percent) / float(js.criterion.max_score) if float(js.criterion.max_score) > 0 else 0
            total_score += weighted
            breakdown.append({
                'criterion': js.criterion.name,
                'score': float(js.score),
                'max_score': float(js.criterion.max_score),
                'weight': float(js.criterion.weight_percent),
                'weighted_score': round(weighted, 2),
            })

        return Response({
            'verification_id': verification_id,
            'submitted_at': submitted_at.isoformat(),
            'total_score': round(total_score, 1),
            'breakdown': breakdown,
            'is_locked': True,
        })

    # ── My scores (pre-fill or check lock status) ─────────────────────────────
    @action(detail=True, methods=['get'])
    def my_scores(self, request, pk=None):
        event = self.get_object()
        candidate_id = request.query_params.get('candidate_id')
        if not candidate_id:
            return Response({'detail': 'candidate_id required.'}, status=status.HTTP_400_BAD_REQUEST)

        scores = JudgeScore.objects.filter(
            judge=request.user,
            candidate_id=candidate_id,
            candidate__event=event,
        )
        serializer = JudgeScoreSerializer(scores, many=True)
        return Response(serializer.data)
