import secrets

from django.contrib.auth import get_user_model
from django.core.cache import cache
from rest_framework import status
from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from random import randint

from .serializers import ForgotPasswordSerializer, LoginSerializer, RegisterSerializer

User = get_user_model()

# ---------------------------------------------------------------------------
# Register
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([AllowAny])
def register(request):
    """
    POST /api/auth/register/
    Body: { username, email, password, confirm_password }
    Returns: { token, user: { id, username, email } }
    """
    serializer = RegisterSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    user = serializer.save()
    token, _ = Token.objects.get_or_create(user=user)

    return Response(
        {
            "token": token.key,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
            },
        },
        status=status.HTTP_201_CREATED,
    )


# ---------------------------------------------------------------------------
# Login
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([AllowAny])
def login(request):
    """
    POST /api/auth/login/
    Body: { identifier, password }   (identifier = username or email)
    Returns: { token, user: { id, username, email } }
    """
    serializer = LoginSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    user = serializer.validated_data["user"]
    token, _ = Token.objects.get_or_create(user=user)

    return Response(
        {
            "token": token.key,
            "user": {
                "id": user.id,
                "username": user.username,
                "email": user.email,
            },
        }
    )


# ---------------------------------------------------------------------------
# Logout
# ---------------------------------------------------------------------------


@api_view(["POST"])
@permission_classes([IsAuthenticated])
def logout(request):
    """
    POST /api/auth/logout/
    Header: Authorization: Token <token>
    Deletes the token so it can no longer be used.
    """
    request.user.auth_token.delete()
    return Response({"detail": "Logged out."}, status=status.HTTP_200_OK)


# ---------------------------------------------------------------------------
# Forgot password  (token-based, no email server required for now)
# ---------------------------------------------------------------------------

_RESET_TOKEN_TTL = 60 * 2  # 2 minutes


@api_view(["POST"])
@permission_classes([AllowAny])
def forgot_password(request):
    """
    POST /api/auth/forgot-password/
    Body: { email }
    Always returns 200 to avoid leaking whether the email exists.
    Stores a short-lived reset token in the cache keyed by email.
    Sends the token via email to the user.
    """
    serializer = ForgotPasswordSerializer(data=request.data)
    if not serializer.is_valid():
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    email = serializer.validated_data["email"]

    try:
        user = User.objects.get(email__iexact=email)
        # Generate a 6-digit random code
        reset_code = str(randint(100000, 999999))
        cache.set(f"pwd_reset:{reset_code}", user.pk, timeout=_RESET_TOKEN_TTL)

        # Send email with the reset code
        from django.core.mail import send_mail
        from django.conf import settings

        send_mail(
            subject="Eventtab - Password Reset Code",
            message=f"""Hello {user.username},

You requested a password reset for your Eventtab account.

Your reset code is:

{reset_code}

This code will expire in 2 minutes.

If you didn't request this, please ignore this email.

— Eventtab Team
""",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False,
        )
    except User.DoesNotExist:
        pass  # Don't reveal non-existence

    return Response(
        {"detail": "If that email is registered, a reset code has been sent."}
    )


@api_view(["POST"])
@permission_classes([AllowAny])
def reset_password(request):
    """
    POST /api/auth/reset-password/
    Body: { reset_token, new_password, confirm_password }
    Validates the token from cache and updates the user's password.
    """
    reset_token = request.data.get("reset_token", "").strip()
    new_password = request.data.get("new_password", "")
    confirm_password = request.data.get("confirm_password", "")

    if not reset_token or not new_password or not confirm_password:
        return Response(
            {"detail": "reset_token, new_password, and confirm_password are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    if new_password != confirm_password:
        return Response(
            {"detail": "Passwords do not match."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    cache_key = f"pwd_reset:{reset_token}"
    user_pk = cache.get(cache_key)

    if user_pk is None:
        return Response(
            {"detail": "Invalid or expired reset code. Request a new one."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    try:
        user = User.objects.get(pk=user_pk)
    except User.DoesNotExist:
        return Response(
            {"detail": "User not found."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    user.set_password(new_password)
    user.save()
    cache.delete(cache_key)

    # Invalidate existing auth tokens so old sessions are kicked out
    Token.objects.filter(user=user).delete()

    return Response({"detail": "Password updated successfully."})


# ---------------------------------------------------------------------------
# Me (authenticated user info)
# ---------------------------------------------------------------------------


@api_view(["GET"])
@permission_classes([IsAuthenticated])
def me(request):
    """
    GET /api/auth/me/
    Header: Authorization: Token <token>
    Returns the current user's profile.
    """
    user = request.user
    return Response(
        {
            "id": user.id,
            "username": user.username,
            "email": user.email,
        }
    )
