from django.conf import settings
from django.db import DatabaseError, connection
from django.http import JsonResponse


def health_check(request):
    try:
        with connection.cursor() as cursor:
            cursor.execute(
                "SELECT current_database(), current_user, inet_server_addr(), inet_server_port()"
            )
            current_database, current_user, server_addr, server_port = cursor.fetchone()
    except DatabaseError as error:
        return JsonResponse(
            {
                "status": "error",
                "backend": "django",
                "database": {
                    "engine": settings.DATABASES["default"]["ENGINE"],
                    "name": settings.DATABASES["default"]["NAME"],
                    "host": settings.DATABASES["default"]["HOST"],
                    "port": settings.DATABASES["default"]["PORT"],
                },
                "message": str(error),
            },
            status=503,
        )

    return JsonResponse(
        {
            "status": "ok",
            "backend": "django",
            "database": {
                "engine": settings.DATABASES["default"]["ENGINE"],
                "name": settings.DATABASES["default"]["NAME"],
                "user": settings.DATABASES["default"]["USER"],
                "host": settings.DATABASES["default"]["HOST"],
                "port": settings.DATABASES["default"]["PORT"],
                "current_database": current_database,
                "current_user": current_user,
                "server_addr": str(server_addr),
                "server_port": server_port,
            },
        }
    )
