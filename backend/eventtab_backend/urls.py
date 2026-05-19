from django.contrib import admin
from django.urls import path

from eventtab_backend.views import health_check


urlpatterns = [
    path("api/health/", health_check, name="health_check"),
    path("admin/", admin.site.urls),
]
