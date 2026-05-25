"""
events/admin.py
===============
Admin configuration for the Eventtab backend.

How admin → mobile sync works
------------------------------
1. Admin saves a Match  →  save_model() detects score/status changes
   and auto-creates an Activity record.
2. Mobile app polls GET /api/events/matches/?updated_after=<ISO timestamp>
   to receive only records changed since its last sync.
3. Every model has an `updated_at` auto-timestamp so the mobile app
   can always detect what changed.
"""

from django.contrib import admin
from django.utils import timezone
from django.utils.html import format_html

from .models import (
    Team, Match, Activity,
    EventCategory, JudgingEvent, Criterion, Candidate, JudgeScore,
)


# ---------------------------------------------------------------------------
# Inlines
# ---------------------------------------------------------------------------

class CriterionInline(admin.TabularInline):
    """Edit scoring criteria directly inside a JudgingEvent."""
    model   = Criterion
    extra   = 1
    fields  = ['order', 'name', 'description', 'max_score', 'weight_percent']
    ordering = ['order']


class CandidateInline(admin.TabularInline):
    """Edit candidates directly inside a JudgingEvent."""
    model   = Candidate
    extra   = 1
    fields  = ['number', 'name', 'description', 'photo']
    ordering = ['number']


class ActivityInline(admin.TabularInline):
    """View auto-generated activities linked to a Match (read-only)."""
    model     = Activity
    extra     = 0
    fields    = ['activity_type', 'title', 'created_at']
    readonly_fields = ['activity_type', 'title', 'created_at']
    can_delete = False

    def has_add_permission(self, request, obj=None):
        return False


# ---------------------------------------------------------------------------
# Team
# ---------------------------------------------------------------------------

@admin.register(Team)
class TeamAdmin(admin.ModelAdmin):
    list_display  = ['abbreviation', 'name', 'color_swatch', 'updated_at']
    search_fields = ['name', 'abbreviation']
    readonly_fields = ['created_at', 'updated_at']
    fieldsets = [
        (None, {'fields': ['name', 'abbreviation', 'logo_icon', 'color', 'description']}),
        ('Timestamps', {'fields': ['created_at', 'updated_at'], 'classes': ['collapse']}),
    ]

    @admin.display(description='Color')
    def color_swatch(self, obj):
        return format_html(
            '<span style="display:inline-block;width:20px;height:20px;'
            'background:{};border-radius:3px;border:1px solid #ccc"></span> {}',
            obj.color, obj.color,
        )


# ---------------------------------------------------------------------------
# Match  (the main sync point)
# ---------------------------------------------------------------------------

@admin.register(Match)
class MatchAdmin(admin.ModelAdmin):
    list_display  = [
        'title', 'sport', 'round_label', 'team_a', 'team_b',
        'score_a', 'score_b', 'score_display', 'scheduled_time',
        'status', 'is_featured', 'updated_at',
    ]
    list_filter   = ['status', 'sport', 'round_label', 'is_featured']
    search_fields = ['title', 'team_a__name', 'team_b__name', 'venue']
    date_hierarchy = 'scheduled_time'
    readonly_fields = ['updated_at']
    list_editable  = ['status', 'score_a', 'score_b', 'is_featured']
    inlines        = [ActivityInline]

    fieldsets = [
        ('Match Info', {
            'fields': [
                'title', 'sport', 'round_label',
                ('team_a', 'team_b'),
                ('score_a', 'score_b'),
                'scheduled_time', 'status', 'is_featured',
            ],
        }),
        ('Venue', {
            'fields': ['venue', 'venue_full'],
        }),
        ('Notes', {
            'fields': ['notes'],
            'classes': ['collapse'],
        }),
        ('Metadata', {
            'fields': ['updated_at'],
            'classes': ['collapse'],
        }),
    ]

    @admin.display(description='Score')
    def score_display(self, obj):
        if obj.score_a is not None and obj.score_b is not None:
            return f"{obj.score_a} – {obj.score_b}"
        return "—"

    def save_model(self, request, obj, form, change):
        """
        Auto-create Activity records when admin changes score or status.
        This is the core of the admin → mobile sync:
          - Score update  → 'match_result' activity
          - Status → live → 'match_scheduled' activity
          - Status → completed → 'match_result' activity
        """
        if change:
            old = Match.objects.get(pk=obj.pk)
            score_changed = (
                old.score_a != obj.score_a or old.score_b != obj.score_b
            )
            status_changed = old.status != obj.status

            super().save_model(request, obj, form, change)

            # Score update
            if score_changed and obj.score_a is not None and obj.score_b is not None:
                Activity.objects.create(
                    activity_type='match_result',
                    title=f"Score Update: {obj.team_a.abbreviation} {obj.score_a} – "
                          f"{obj.score_b} {obj.team_b.abbreviation}",
                    description=f"{obj.title} score updated.",
                    match=obj,
                    icon='emoji_events',
                )

            # Status change
            if status_changed:
                if obj.status == 'live':
                    Activity.objects.create(
                        activity_type='match_scheduled',
                        title=f"🔴 LIVE: {obj.team_a.abbreviation} vs {obj.team_b.abbreviation}",
                        description=f"{obj.title} is now live at {obj.venue}.",
                        match=obj,
                        icon='sports',
                    )
                elif obj.status == 'completed':
                    winner = obj.winner
                    Activity.objects.create(
                        activity_type='match_result',
                        title=f"Final: {obj.team_a.abbreviation} {obj.score_a} – "
                              f"{obj.score_b} {obj.team_b.abbreviation}",
                        description=(
                            f"{winner.name} wins {obj.title}!"
                            if winner else f"{obj.title} ended in a draw."
                        ),
                        match=obj,
                        icon='emoji_events',
                    )
        else:
            super().save_model(request, obj, form, change)


# ---------------------------------------------------------------------------
# Activity
# ---------------------------------------------------------------------------

@admin.register(Activity)
class ActivityAdmin(admin.ModelAdmin):
    list_display   = ['title', 'activity_type', 'match', 'created_at']
    list_filter    = ['activity_type']
    search_fields  = ['title', 'description']
    date_hierarchy = 'created_at'
    readonly_fields = ['created_at']


# ---------------------------------------------------------------------------
# EventCategory
# ---------------------------------------------------------------------------

@admin.register(EventCategory)
class EventCategoryAdmin(admin.ModelAdmin):
    list_display  = ['name', 'category_type', 'color_swatch', 'event_count']
    search_fields = ['name']

    @admin.display(description='Color')
    def color_swatch(self, obj):
        return format_html(
            '<span style="display:inline-block;width:20px;height:20px;'
            'background:{};border-radius:3px;border:1px solid #ccc"></span>',
            obj.color,
        )

    @admin.display(description='Events')
    def event_count(self, obj):
        return obj.events.count()


# ---------------------------------------------------------------------------
# JudgingEvent  (with inline Criteria + Candidates)
# ---------------------------------------------------------------------------

@admin.register(JudgingEvent)
class JudgingEventAdmin(admin.ModelAdmin):
    list_display     = ['title', 'category', 'date', 'time', 'venue', 'status',
                        'candidate_count', 'criteria_count']
    list_filter      = ['status', 'category']
    search_fields    = ['title', 'venue']
    filter_horizontal = ['assigned_judges']
    inlines          = [CriterionInline, CandidateInline]

    @admin.display(description='Candidates')
    def candidate_count(self, obj):
        return obj.candidates.count()

    @admin.display(description='Criteria')
    def criteria_count(self, obj):
        return obj.criteria.count()


# ---------------------------------------------------------------------------
# Criterion / Candidate / JudgeScore (standalone access)
# ---------------------------------------------------------------------------

@admin.register(Criterion)
class CriterionAdmin(admin.ModelAdmin):
    list_display  = ['name', 'event', 'max_score', 'weight_percent', 'order']
    list_filter   = ['event']
    ordering      = ['event', 'order']


@admin.register(Candidate)
class CandidateAdmin(admin.ModelAdmin):
    list_display  = ['number', 'name', 'event']
    list_filter   = ['event']
    search_fields = ['name']


@admin.register(JudgeScore)
class JudgeScoreAdmin(admin.ModelAdmin):
    list_display    = ['judge', 'candidate', 'criterion', 'score',
                       'is_locked', 'submitted_at']
    list_filter     = ['is_locked', 'candidate__event']
    readonly_fields = ['verification_id', 'submitted_at']
    search_fields   = ['judge__username', 'candidate__name']
