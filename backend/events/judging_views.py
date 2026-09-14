import uuid
from decimal import Decimal
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore
from .judge_data import user_assigned_to_judging_event
from .judging_serializers import (
    EventCategorySerializer, JudgingEventListSerializer,
    JudgingEventDetailSerializer, JudgeScoreSerializer,
    SubmitScoresSerializer, SaveDraftSerializer,
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

    # Returned for correction
    returned = JudgeScore.objects.filter(
        judge=user, approval_status="rejected"
    ).select_related("candidate", "candidate__event").order_by("-reviewed_at")
    seen_ret = set()
    for js in returned:
        key = js.candidate_id
        if key in seen_ret:
            continue
        seen_ret.add(key)
        notifications.insert(
            0,
            {
                "id": f"returned_{js.candidate_id}",
                "icon": "info",
                "icon_color": "#E53935",
                "title": "Score returned for correction",
                "body": (
                    f'Your score for {js.candidate.name} in "{js.candidate.event.title}" '
                    f'was returned. Reason: {js.review_note or "Please revise and resubmit."}'
                ),
                "time": (
                    js.reviewed_at.isoformat()
                    if js.reviewed_at
                    else (js.submitted_at.isoformat() if js.submitted_at else "")
                ),
                "is_unread": True,
                "event_id": js.candidate.event_id,
                "candidate_id": js.candidate_id,
                "type": "returned",
            },
        )

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
            scores_qs = JudgeScore.objects.filter(
                candidate=candidate,
                approval_status="approved",
            ).select_related('criterion')
            total = Decimal('0.00')
            for js in scores_qs:
                if js.criterion.max_score > 0:
                    total += js.score * js.criterion.weight_percent / js.criterion.max_score
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

        # Official leaderboard: only candidates with tabulator-approved scores.
        results = [r for r in results if r['is_official']]
        results.sort(key=lambda x: x['total_score'], reverse=True)
        for i, r in enumerate(results):
            r['rank'] = i + 1

        serializer = CandidateStandingSerializer(results, many=True)
        return Response(serializer.data)

    # ── Save draft (unlocked, not official) ──────────────────────────────────
    @action(detail=True, methods=['post'])
    def save_draft(self, request, pk=None):
        event = self.get_object()
        if not user_assigned_to_judging_event(request.user, event.id):
            return Response({'detail': 'Not assigned to this event.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = SaveDraftSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        candidate_id = serializer.validated_data['candidate_id']
        scores_data = serializer.validated_data['scores']
        draft_step = serializer.validated_data.get('draft_step') or 0

        try:
            candidate = Candidate.objects.get(id=candidate_id, event=event)
        except Candidate.DoesNotExist:
            return Response({'detail': 'Candidate not found.'}, status=status.HTTP_404_NOT_FOUND)

        existing = JudgeScore.objects.filter(judge=request.user, candidate=candidate)
        if existing.filter(approval_status="approved").exists():
            return Response({'detail': 'Scores already approved.'}, status=status.HTTP_400_BAD_REQUEST)
        if existing.filter(approval_status="pending", is_locked=True, is_draft=False).exists():
            return Response(
                {'detail': 'Scores already submitted. Waiting for review.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        active_stage = event.stages.filter(is_active=True).first()
        saved = 0
        for item in scores_data:
            try:
                criterion = Criterion.objects.get(id=item['criterion_id'], event=event)
            except Criterion.DoesNotExist:
                continue
            score_value = float(item['score'])
            min_s = float(criterion.min_score or 0)
            max_s = float(criterion.max_score)
            score_value = min(max(score_value, min_s), max_s)
            comment = item.get('comment') or ''
            JudgeScore.objects.update_or_create(
                judge=request.user,
                candidate=candidate,
                criterion=criterion,
                defaults={
                    'score': score_value,
                    'comment': comment,
                    'is_locked': False,
                    'is_draft': True,
                    'draft_step': draft_step,
                    'submitted_at': None,
                    'verification_id': '',
                    'approval_status': 'pending',
                    'stage': active_stage,
                },
            )
            saved += 1

        return Response({
            'detail': 'Draft saved successfully.',
            'saved_count': saved,
            'draft_step': draft_step,
            'scoring_status': 'draft',
            'status_label': 'Draft Saved',
        })

    # ── Submit scores (locks permanently) ────────────────────────────────────
    @action(detail=True, methods=['post'])
    def submit_scores(self, request, pk=None):
        event = self.get_object()
        if not user_assigned_to_judging_event(request.user, event.id):
            return Response({'detail': 'Not assigned to this event.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = SubmitScoresSerializer(data=request.data)
        if not serializer.is_valid():
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

        candidate_id = serializer.validated_data['candidate_id']
        scores_data = serializer.validated_data['scores']

        try:
            candidate = Candidate.objects.get(id=candidate_id, event=event)
        except Candidate.DoesNotExist:
            return Response({'detail': 'Candidate not found.'}, status=status.HTTP_404_NOT_FOUND)

        # Prevent re-submission while pending/approved (allow after reject).
        existing = JudgeScore.objects.filter(
            judge=request.user, candidate=candidate
        )
        if existing.filter(approval_status="approved").exists():
            return Response(
                {'detail': 'Scores already approved by tabulator.'},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if existing.filter(approval_status="pending", is_locked=True, is_draft=False).exists():
            return Response(
                {'detail': 'Scores already submitted and awaiting tabulator review.'},
                status=status.HTTP_400_BAD_REQUEST,
            )

        # Validate all required criteria present
        criteria = list(Criterion.objects.filter(event=event).order_by('order', 'id'))
        active_stage = event.stages.filter(is_active=True).first()
        if active_stage:
            stage_criteria = [c for c in criteria if c.stage_id in (None, active_stage.id)]
            if stage_criteria:
                criteria = stage_criteria

        by_id = {int(item['criterion_id']): item for item in scores_data}
        for criterion in criteria:
            item = by_id.get(criterion.id)
            if item is None:
                return Response(
                    {'detail': f'Missing score for criterion "{criterion.name}".'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            score_value = float(item['score'])
            min_s = float(criterion.min_score or 0)
            max_s = float(criterion.max_score)
            if score_value < min_s or score_value > max_s:
                return Response(
                    {'detail': f'Score for "{criterion.name}" must be between {min_s} and {max_s}.'},
                    status=status.HTTP_400_BAD_REQUEST,
                )
            comment = (item.get('comment') or '').strip()
            need_comment = criterion.comment_required
            thr = criterion.low_score_comment_threshold
            if thr is not None and score_value <= float(thr):
                need_comment = True
            if need_comment and not comment:
                return Response(
                    {'detail': f'Comment required for criterion "{criterion.name}".'},
                    status=status.HTTP_400_BAD_REQUEST,
                )

        verification_id = str(uuid.uuid4())[:13].upper()
        submitted_at = timezone.now()
        created_scores = []

        for criterion in criteria:
            item = by_id[criterion.id]
            score_value = float(item['score'])
            comment = item.get('comment') or ''
            prev = existing.filter(criterion=criterion).first()
            previous_score = prev.score if prev and prev.is_locked else None

            judge_score, _ = JudgeScore.objects.update_or_create(
                judge=request.user,
                candidate=candidate,
                criterion=criterion,
                defaults={
                    'score': score_value,
                    'comment': comment,
                    'is_locked': True,
                    'is_draft': False,
                    'draft_step': 0,
                    'submitted_at': submitted_at,
                    'verification_id': verification_id,
                    'approval_status': 'pending',
                    'reviewed_at': None,
                    'review_note': '',
                    'previous_score': previous_score,
                    'stage': active_stage,
                }
            )
            created_scores.append(judge_score)

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
                'comment': js.comment,
            })

        return Response({
            'verification_id': verification_id,
            'submitted_at': submitted_at.isoformat(),
            'total_score': round(total_score, 1),
            'breakdown': breakdown,
            'is_locked': True,
            'approval_status': 'pending',
            'status_label': 'PENDING VERIFICATION',
            'scoring_status': 'submitted',
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
