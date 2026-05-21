from rest_framework import serializers
from .models import Team, Match, Activity


class TeamSerializer(serializers.ModelSerializer):
    class Meta:
        model = Team
        fields = ['id', 'name', 'abbreviation', 'logo_icon', 'color']


class MatchSerializer(serializers.ModelSerializer):
    team_a = TeamSerializer(read_only=True)
    team_b = TeamSerializer(read_only=True)
    winner = TeamSerializer(read_only=True)
    
    class Meta:
        model = Match
        fields = [
            'id', 'title', 'sport', 'team_a', 'team_b', 
            'score_a', 'score_b', 'scheduled_time', 'status',
            'is_featured', 'venue', 'winner'
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
