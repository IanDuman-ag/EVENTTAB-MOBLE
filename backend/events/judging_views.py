import uuid
from django.utils import timezone
from rest_framework import viewsets, permissions, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore
from .judging_serializers import (
    EventCategorySerializer, JudgingEventListSerializer,
    JudgingEventDetailSerializer, JudgeScoreSerializer, SubmitScoresSerializer
)


class EventCategoryViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = EventCategory.objects.all()
    serializer_class = EventCategorySerializer
    permission_classes = [permissions.IsAuthenticated]

    @action(detail=True, methods=['get'])
    def events(self, request, pk=None):
        category = self.get_object()
        events = category.events.all()
        serializer = JudgingEventListSerializer(events, many=True)
        return Response(serializer.data)


class JudgingEventViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = JudgingEvent.objects.all()
    permission_classes = [permissions.IsAuthenticated]

    def get_serializer_class(self):
        if self.action == 'retrieve':
            return JudgingEventDetailSerializer
        return JudgingEventListSerializer

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

        # Check if already locked
        existing_locked = JudgeScore.objects.filter(
            judge=request.user, candidate=candidate, is_locked=True
        ).exists()
        if existing_locked:
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

            # Clamp score to max
            score_value = min(score_value, float(criterion.max_score))
            score_value = max(score_value, 0)

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

        # Calculate weighted total
        total_score = 0
        breakdown = []
        for js in created_scores:
            weighted = float(js.score) * float(js.criterion.weight_percent) / float(js.criterion.max_score)
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
