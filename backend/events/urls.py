from django.urls import path, include
from rest_framework.routers import DefaultRouter

# General viewer endpoints (teams, matches, activities, rankings)
from .views import TeamViewSet, MatchViewSet, ActivityViewSet, JudgingEventViewSet as RankingsEventViewSet

# Judge-specific endpoints (categories, event detail with criteria/candidates, scoring)
from .judging_views import EventCategoryViewSet, JudgingEventViewSet, judge_notifications
from .judge_views import (
    judge_assignment_detail,
    judge_assignments,
    judge_dashboard,
    judge_profile,
    judge_score_history,
)
from .scorer_views import (
    scorer_assignments,
    scorer_bracket,
    scorer_dashboard,
    scorer_history,
    scorer_matches,
    scorer_match_detail,
    scorer_profile,
    scorer_update_bracket_score,
    scorer_update_score,
)
from .viewer_views import (
    viewer_dashboard,
    viewer_events,
    viewer_live,
    viewer_profile,
    viewer_rankings,
)
from .tabulator_views import tabulator_queue, tabulator_review

router = DefaultRouter()
router.register(r'teams', TeamViewSet)
router.register(r'matches', MatchViewSet)
router.register(r'activities', ActivityViewSet)
router.register(r'categories', EventCategoryViewSet)
router.register(r'judging-events', JudgingEventViewSet)
router.register(r'rankings-events', RankingsEventViewSet, basename='rankings-events')

urlpatterns = [
    path('', include(router.urls)),
    path('judge-notifications/', judge_notifications, name='judge_notifications'),
    path('judge/dashboard/', judge_dashboard, name='judge_dashboard'),
    path('judge/assignments/', judge_assignments, name='judge_assignments'),
    path(
        'judge/assignments/<int:judging_event_id>/',
        judge_assignment_detail,
        name='judge_assignment_detail',
    ),
    path('judge/score-history/', judge_score_history, name='judge_score_history'),
    path('judge/profile/', judge_profile, name='judge_profile'),
    path('scorer/dashboard/', scorer_dashboard, name='scorer_dashboard'),
    path('scorer/assignments/', scorer_assignments, name='scorer_assignments'),
    path('scorer/profile/', scorer_profile, name='scorer_profile'),
    path('scorer/bracket/', scorer_bracket, name='scorer_bracket'),
    path('scorer/history/', scorer_history, name='scorer_history'),
    path('scorer/matches/', scorer_matches, name='scorer_matches'),
    path('scorer/matches/<int:match_id>/score/', scorer_update_score, name='scorer_update_score'),
    path(
        'scorer/bracket/matches/<int:match_id>/',
        scorer_match_detail,
        name='scorer_match_detail',
    ),
    path(
        'scorer/bracket/matches/<int:match_id>/score/',
        scorer_update_bracket_score,
        name='scorer_update_bracket_score',
    ),
    path('viewer/dashboard/', viewer_dashboard, name='viewer_dashboard'),
    path('viewer/events/', viewer_events, name='viewer_events'),
    path('viewer/live/', viewer_live, name='viewer_live'),
    path('viewer/rankings/', viewer_rankings, name='viewer_rankings'),
    path('viewer/profile/', viewer_profile, name='viewer_profile'),
    path('tabulator/queue/', tabulator_queue, name='tabulator_queue'),
    path('tabulator/review/', tabulator_review, name='tabulator_review'),
]
