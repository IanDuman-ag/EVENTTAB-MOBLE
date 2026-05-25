from rest_framework import serializers
from .models import Team, Match, Activity, EventCategory, JudgingEvent, Candidate, JudgeScore, Criterion
from django.db.models import Sum
from decimal import Decimal


class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = ['id', 'name', 'abbreviation', 'logo_icon', 'color',
                  'description', 'updated_at']


class MatchSerializer(serializers.ModelSerializer):
    team_a      = TeamSerializer(read_only=True)
    team_b      = TeamSerializer(read_only=True)
    winner      = TeamSerializer(read_only=True)
    round_label_display = serializers.CharField(
        source='get_round_label_display', read_only=True)

    class Meta:
        model = Match
        fields = [
            'id', 'title', 'sport', 'round_label', 'round_label_display',
            'team_a', 'team_b', 'score_a', 'score_b',
            'scheduled_time', 'status', 'is_featured',
            'venue', 'venue_full', 'notes', 'winner', 'updated_at',
        ]


class ActivitySerializer(serializers.ModelSerializer):
    match = MatchSerializer(read_only=True)
    time_ago = serializers.SerializerMethodField()
    
    class Meta:
        model = Activity
        fields = ['id', 'activity_type', 'title', 'description', 'match', 'icon', 'created_at', 'time_ago']
    
    def get_time_ago(self, obj):
        """Calculate human-readable time difference"""
        from django.utils import timezone
        diff = timezone.now() - obj.created_at
        
        if diff.days > 0:
            return f"{diff.days} DAY{'S' if diff.days > 1 else ''} AGO"
        elif diff.seconds >= 3600:
            hours = diff.seconds // 3600
            return f"{hours} HOUR{'S' if hours > 1 else ''} AGO"
        elif diff.seconds >= 60:
            minutes = diff.seconds // 60
            return f"{minutes} MINUTE{'S' if minutes > 1 else ''} AGO"
        else:
            return "JUST NOW"


# ---------------------------------------------------------------------------
# Rankings serializers
# ---------------------------------------------------------------------------

class EventCategorySerializer(serializers.ModelSerializer):
    event_count = serializers.SerializerMethodField()

    class Meta:
        model = EventCategory
        fields = ['id', 'name', 'category_type', 'description', 'icon', 'color', 'event_count']

    def get_event_count(self, obj):
        return obj.events.count()


class JudgingEventSerializer(serializers.ModelSerializer):
    category_name = serializers.CharField(source='category.name', read_only=True)
    candidate_count = serializers.SerializerMethodField()

    class Meta:
        model = JudgingEvent
        fields = ['id', 'title', 'category', 'category_name', 'date', 'time',
                  'venue', 'status', 'description', 'candidate_count']

    def get_candidate_count(self, obj):
        return obj.candidates.count()


class CandidateStandingSerializer(serializers.Serializer):
    """Serializer for computed candidate standings (rank + total score)."""
    rank = serializers.IntegerField()
    candidate_id = serializers.IntegerField()
    name = serializers.CharField()
    number = serializers.IntegerField()
    total_score = serializers.DecimalField(max_digits=10, decimal_places=2)
    is_live = serializers.BooleanField()
