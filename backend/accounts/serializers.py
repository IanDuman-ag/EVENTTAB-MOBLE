from django.contrib.auth import authenticate, get_user_model
from django.contrib.auth.hashers import check_password
from django.contrib.auth.models import Group
from django.db import connection
from django.contrib.auth.password_validation import validate_password
from rest_framework import serializers

User = get_user_model()


class RegisterSerializer(serializers.ModelSerializer):
    """Validates and creates a new user account."""

    password = serializers.CharField(
        write_only=True,
        required=True,
        validators=[validate_password],
    )
    confirm_password = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ("username", "email", "password", "confirm_password")

    def validate(self, attrs):
        if attrs["password"] != attrs["confirm_password"]:
            raise serializers.ValidationError(
                {"confirm_password": "Passwords do not match."}
            )
        return attrs

    def validate_username(self, value):
        if User.objects.filter(username__iexact=value).exists():
            raise serializers.ValidationError("This username is already taken.")
        return value

    def validate_email(self, value):
        if User.objects.filter(email__iexact=value).exists():
            raise serializers.ValidationError("This email is already registered.")
        return value

    def create(self, validated_data):
        validated_data.pop("confirm_password")
        return User.objects.create_user(**validated_data)


class LoginSerializer(serializers.Serializer):
    """Accepts username or email + password and returns the authenticated user."""

    identifier = serializers.CharField()
    password = serializers.CharField(write_only=True)

    def _get_legacy_user(self, identifier):
        identifier = identifier.strip()
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT id, username, email, password, is_active, is_staff, is_superuser
                FROM auth_user
                WHERE username = %s OR LOWER(email) = LOWER(%s)
                ORDER BY id
                LIMIT 1
                """,
                [identifier, identifier],
            )
            row = cursor.fetchone()

        if row is None:
            return None

        return {
            "id": row[0],
            "username": row[1],
            "email": row[2],
            "password": row[3],
            "is_active": row[4],
            "is_staff": row[5],
            "is_superuser": row[6],
        }

    def _get_legacy_groups(self, legacy_user_id):
        with connection.cursor() as cursor:
            cursor.execute(
                """
                SELECT g.name
                FROM auth_group g
                INNER JOIN auth_user_groups ug ON ug.group_id = g.id
                WHERE ug.user_id = %s
                ORDER BY g.name
                """,
                [legacy_user_id],
            )
            return [row[0] for row in cursor.fetchall()]

    def _sync_legacy_user(self, legacy_user, password):
        existing = User.objects.filter(email__iexact=legacy_user["email"]).first()
        if existing is None:
            existing = User.objects.filter(username=legacy_user["username"]).first()

        if existing is None:
            user = User(
                username=legacy_user["username"],
                email=legacy_user["email"],
                is_active=legacy_user["is_active"],
                is_staff=legacy_user["is_staff"],
                is_superuser=legacy_user["is_superuser"],
            )
            user.set_password(password)
            user.save()
        else:
            user = existing
            changed_fields = []
            if user.username != legacy_user["username"]:
                user.username = legacy_user["username"]
                changed_fields.append("username")
            if user.email.lower() != legacy_user["email"].lower():
                user.email = legacy_user["email"]
                changed_fields.append("email")
            if user.is_active != legacy_user["is_active"]:
                user.is_active = legacy_user["is_active"]
                changed_fields.append("is_active")
            if user.is_staff != legacy_user["is_staff"]:
                user.is_staff = legacy_user["is_staff"]
                changed_fields.append("is_staff")
            if user.is_superuser != legacy_user["is_superuser"]:
                user.is_superuser = legacy_user["is_superuser"]
                changed_fields.append("is_superuser")
            if not user.check_password(password):
                user.set_password(password)
                changed_fields.append("password")
            if changed_fields:
                user.save()

        group_names = self._get_legacy_groups(legacy_user["id"])
        if group_names:
            groups = [Group.objects.get_or_create(name=name)[0] for name in group_names]
            user.groups.set(groups)

        return user

    def validate(self, attrs):
        identifier = attrs["identifier"].strip()
        password = attrs["password"]

        # Try username first, then email
        user = authenticate(username=identifier, password=password)
        if user is None:
            # Try resolving email → username
            try:
                matched = User.objects.get(email__iexact=identifier)
                user = authenticate(username=matched.username, password=password)
            except User.DoesNotExist:
                pass

        if user is None:
            legacy_user = self._get_legacy_user(identifier)
            if legacy_user and check_password(password, legacy_user["password"]):
                user = self._sync_legacy_user(legacy_user, password)

        if user is None:
            raise serializers.ValidationError(
                "Invalid username/email or password."
            )

        if not user.is_active:
            raise serializers.ValidationError("This account has been disabled.")

        attrs["user"] = user
        return attrs


class ForgotPasswordSerializer(serializers.Serializer):
    """Accepts an email and returns a reset token if the account exists."""

    email = serializers.EmailField()

    def validate_email(self, value):
        # We don't reveal whether the email exists (security best practice).
        # The view handles the lookup separately.
        return value.strip().lower()
