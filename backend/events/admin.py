from django.contrib import admin
from .models import Team, Match, Activity


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
