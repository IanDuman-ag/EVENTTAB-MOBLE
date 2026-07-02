"""Resolve access codes from Django admin or EventTab admin portal."""

from django.contrib.auth.models import Group
from django.db import connection
from rest_framework import serializers

from .models import AccessCode, User


def _legacy_role(auth_user_id):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT LOWER(g.name)
            FROM auth_group g
            INNER JOIN auth_user_groups ug ON ug.group_id = g.id
            WHERE ug.user_id = %s
            """,
            [auth_user_id],
        )
        groups = {row[0] for row in cursor.fetchall()}

    if "judge" in groups:
        return "judge"
    if "scorer" in groups:
        return "scorer"
    return None


def _legacy_group_names(auth_user_id):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT g.name
            FROM auth_group g
            INNER JOIN auth_user_groups ug ON ug.group_id = g.id
            WHERE ug.user_id = %s
            ORDER BY g.name
            """,
            [auth_user_id],
        )
        return [row[0] for row in cursor.fetchall()]


def _sync_legacy_auth_user(legacy_user):
    email = (legacy_user["email"] or "").strip()
    if not email:
        email = f"{legacy_user['username']}@access.eventtab.local"

    user = User.objects.filter(username=legacy_user["username"]).first()
    if user is None:
        user = User.objects.filter(email__iexact=email).first()

    if user is None:
        user = User(
            username=legacy_user["username"],
            email=email,
            is_active=legacy_user["is_active"],
            is_staff=legacy_user["is_staff"],
            is_superuser=legacy_user["is_superuser"],
        )
        user.password = legacy_user["password"]
        user.save()
    else:
        user.is_active = legacy_user["is_active"]
        user.is_staff = legacy_user["is_staff"]
        user.is_superuser = legacy_user["is_superuser"]
        if not user.email:
            user.email = email
        user.save()

    group_names = _legacy_group_names(legacy_user["id"])
    if group_names:
        groups = [Group.objects.get_or_create(name=name)[0] for name in group_names]
        user.groups.set(groups)

    return user


def _resolve_portal_access_code(code):
    with connection.cursor() as cursor:
        cursor.execute(
            """
            SELECT au.id, au.username, au.email, au.password,
                   au.is_active, au.is_staff, au.is_superuser
            FROM events_assignmentaccountprofile p
            INNER JOIN auth_user au ON au.id = p.user_id
            WHERE UPPER(p.access_code) = %s
            LIMIT 1
            """,
            [code],
        )
        row = cursor.fetchone()

    if row is None:
        return None

    legacy = {
        "id": row[0],
        "username": row[1],
        "email": row[2],
        "password": row[3],
        "is_active": row[4],
        "is_staff": row[5],
        "is_superuser": row[6],
    }

    if not legacy["is_active"]:
        raise serializers.ValidationError(
            {"access_code": "This access code has been disabled."}
        )

    role = _legacy_role(legacy["id"])
    if role is None:
        raise serializers.ValidationError(
            {"access_code": "Account role is not configured."}
        )

    user = _sync_legacy_auth_user(legacy)
    return user, role, legacy["username"]


def resolve_access_code_login(code):
    """
    Look up an access code from:
    1. accounts_access_code (Django admin)
    2. events_assignmentaccountprofile (EventTab admin portal)
    Returns (user, role, label).
    """
    normalized = code.strip().upper()
    if not normalized:
        raise serializers.ValidationError({"access_code": "Access code is required."})

    try:
        access = AccessCode.objects.select_related("user").get(
            code__iexact=normalized,
            is_active=True,
        )
        if access.user_id is None:
            access.save()
        user = access.user
        if user is None or not user.is_active:
            raise serializers.ValidationError(
                {"access_code": "This access code has been disabled."}
            )
        label = access.label or access.get_role_display()
        return user, access.role, label
    except AccessCode.DoesNotExist:
        pass

    portal = _resolve_portal_access_code(normalized)
    if portal is not None:
        return portal

    raise serializers.ValidationError({"access_code": "Invalid access code."})
