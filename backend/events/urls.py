from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import TeamViewSet, MatchViewSet, ActivityViewSet

router = DefaultRouter()
router.register(r'teams', TeamViewSet)
router.register(r'matches', MatchViewSet)
router.register(r'activities', ActivityViewSet)

urlpatterns = [
    path('', include(router.urls)),
]
