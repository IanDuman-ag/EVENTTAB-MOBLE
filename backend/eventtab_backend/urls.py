from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import include, path

from eventtab_backend.views import health_check

urlpatterns = [
    path("api/health/", health_check, name="health_check"),
    path("api/auth/", include("accounts.urls")),
    path("api/events/", include("events.urls")),
    path("admin/", admin.site.urls),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
