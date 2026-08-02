from rest_framework import serializers
from .models import EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore, JudgingStage


class EventCategorySerializer(serializers.ModelSerializer):
    event_count = serializers.SerializerMethodField()

    class Meta:
        model = EventCategory
        fields = ['id', 'name', 'category_type', 'description', 'icon', 'color', 'event_count']

    def get_event_count(self, obj):
        return obj.events.count()


class CriterionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Criterion
        fields = [
            'id', 'name', 'description', 'max_score', 'min_score', 'weight_percent',
            'order', 'comment_enabled', 'comment_required',
            'low_score_comment_threshold', 'decimal_places', 'stage',
        ]


class CandidateSerializer(serializers.ModelSerializer):
    class Meta:
        model = Candidate
        fields = ['id', 'name', 'number', 'photo', 'description', 'department']


class JudgingStageSerializer(serializers.ModelSerializer):
    class Meta:
        model = JudgingStage
        fields = [
            'id', 'name', 'description', 'weight_percent', 'order', 'status',
            'qualifier_count', 'scoring_deadline', 'is_active',
        ]


class JudgingEventListSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_type = serializers.CharField(source='category.category_type', read_only=True)
    candidate_count = serializers.SerializerMethodField()

    class Meta:
        model = JudgingEvent
        fields = ['id', 'title', 'category_name', 'category_type', 'date', 'time', 'venue', 'status', 'candidate_count']

    def get_candidate_count(self, obj):
        return obj.candidates.count()


class JudgingEventDetailSerializer(serializers.ModelSerializer):
    criteria = CriterionSerializer(many=True, read_only=True)
    candidates = CandidateSerializer(many=True, read_only=True)
    stages = JudgingStageSerializer(many=True, read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    category_type = serializers.CharField(source='category.category_type', read_only=True)
    candidate_count = serializers.SerializerMethodField()

    class Meta:
        model = JudgingEvent
        fields = [
            'id', 'title', 'category_name', 'category_type', 'date', 'time', 'venue',
            'status', 'description', 'instructions', 'faculty_in_charge',
            'criteria', 'candidates', 'stages', 'candidate_count',
        ]

    def get_candidate_count(self, obj):
        return obj.candidates.count()


class JudgeScoreSerializer(serializers.ModelSerializer):
    criterion_name = serializers.CharField(source='criterion.name', read_only=True)
    criterion_max = serializers.DecimalField(
        source='criterion.max_score', max_digits=5, decimal_places=1, read_only=True
    )

    class Meta:
        model = JudgeScore
        fields = [
            'id', 'criterion', 'criterion_name', 'criterion_max', 'score', 'comment',
            'is_locked', 'is_draft', 'draft_step', 'submitted_at', 'verification_id',
            'approval_status', 'review_note', 'previous_score',
        ]


class ScoreItemSerializer(serializers.Serializer):
    criterion_id = serializers.IntegerField()
    score = serializers.DecimalField(max_digits=5, decimal_places=2)
    comment = serializers.CharField(required=False, allow_blank=True, default="")


class SubmitScoresSerializer(serializers.Serializer):
    candidate_id = serializers.IntegerField()
    scores = ScoreItemSerializer(many=True)
    draft_step = serializers.IntegerField(required=False, default=0)

    def validate_scores(self, value):
        if not value:
            raise serializers.ValidationError("At least one score is required.")
        return value


class SaveDraftSerializer(serializers.Serializer):
    candidate_id = serializers.IntegerField()
    scores = ScoreItemSerializer(many=True)
    draft_step = serializers.IntegerField(required=False, default=0)
