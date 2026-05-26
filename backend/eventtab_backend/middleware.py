import ipaddress
from urllib.parse import urlparse

from decouple import config
from django.http import HttpResponse


def _csv(value):
    return [item.strip() for item in value.split(",") if item.strip()]


class LocalDevelopmentCorsMiddleware:
    """
    Lightweight CORS middleware for local development.
    In production, replace this with django-cors-headers.
    """

    _ALLOWED_METHODS = "GET, POST, OPTIONS"
    _ALLOWED_HEADERS = "Content-Type, Authorization"

    def __init__(self, get_response):
        self.get_response = get_response
        self.allowed_origins = set(config("CORS_ALLOWED_ORIGINS", default="", cast=_csv))
        self.allow_localhost = config("DJANGO_DEBUG", default=True, cast=bool)

    def __call__(self, request):
        if request.method == "OPTIONS":
            response = HttpResponse(status=204)
        else:
            response = self.get_response(request)

        origin = request.headers.get("Origin")
        if self._is_allowed_origin(origin):
            response["Access-Control-Allow-Origin"] = origin
            response["Vary"] = "Origin"
            response["Access-Control-Allow-Methods"] = self._ALLOWED_METHODS
            response["Access-Control-Allow-Headers"] = self._ALLOWED_HEADERS

        return response

    def _is_allowed_origin(self, origin):
        if not origin:
            return False
        if origin in self.allowed_origins:
            return True
        if not self.allow_localhost:
            return False

        try:
            hostname = urlparse(origin).hostname
        except ValueError:
            return False

        if not hostname:
            return False

        if hostname in {"localhost", "127.0.0.1"}:
            return True

        try:
            address = ipaddress.ip_address(hostname)
        except ValueError:
            return False

        return address.is_private or address.is_loopback
