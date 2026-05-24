from django.urls import path, include
from rest_framework.routers import DefaultRouter

# General viewer endpoints (teams, matches, activities, rankings)
from .views import TeamViewSet, MatchViewSet, ActivityViewSet, JudgingEventViewSet as RankingsEventViewSet

# Judge-specific endpoints (categories, event detail with criteria/candidates, scoring)
from .judging_views import EventCategoryViewSet, JudgingEventViewSet, judge_notifications

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
]
