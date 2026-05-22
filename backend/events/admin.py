from django.contrib import admin
from .models import Team, Match, Activity, EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore


@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display = ['name', 'abbreviation', 'color']
    search_fields = ['name', 'abbreviation']


@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display = ['title', 'team_a', 'team_b', 'score_a', 'score_b', 'scheduled_time', 'status', 'is_featured']
    list_filter = ['status', 'sport', 'is_featured']
    search_fields = ['title', 'team_a__name', 'team_b__name']
    date_hierarchy = 'scheduled_time'


@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display = ['title', 'activity_type', 'created_at']
    list_filter = ['activity_type', 'created_at']
    search_fields = ['title', 'description']
    date_hierarchy = 'created_at'


@admin.register(EventCategory)
class EventCategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'category_type', 'color']


@admin.register(JudgingEvent)
class JudgingEventAdmin(admin.ModelAdmin):
    list_display = ['title', 'category', 'date', 'time', 'venue', 'status']
    list_filter = ['status', 'category']
    filter_horizontal = ['assigned_judges']


@admin.register(Criterion)
class CriterionAdmin(admin.ModelAdmin):
    list_display = ['name', 'event', 'max_score', 'weight_percent', 'order']


@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display = ['number', 'name', 'event']


@admin.register(JudgeScore)
class JudgeScoreAdmin(admin.ModelAdmin):
    list_display = ['judge', 'candidate', 'criterion', 'score', 'is_locked', 'submitted_at']
    list_filter = ['is_locked']
    readonly_fields = ['verification_id', 'submitted_at']
