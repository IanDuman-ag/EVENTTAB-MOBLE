from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TeamViewSet, MatchViewSet, ActivityViewSet
from .judging_views import EventCategoryViewSet, JudgingEventViewSet

router = DefaultRouter()
router.register(r'teams', TeamViewSet)
router.register(r'matches', MatchViewSet)
router.register(r'activities', ActivityViewSet)
router.register(r'categories', EventCategoryViewSet)
router.register(r'judging-events', JudgingEventViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
