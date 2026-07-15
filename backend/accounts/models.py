import secrets

from django.conf import settings
from django.contrib.auth.models import AbstractUser, Group
from django.db import models


class User(AbstractUser):
    """
    Custom user model. Extends Django's AbstractUser so we can add
    profile fields later without a migration headache.
    """

    email = models.EmailField(unique=True)

    # Allow login with either username or email
    USERNAME_FIELD = "username"
    REQUIRED_FIELDS = ["email"]

    class Meta:
        db_table = "accounts_user"

    def __str__(self):
        return self.username


class AccessCode(models.Model):
    """One-time or reusable access codes created by admin for judge/scorer login."""

    ROLE_CHOICES = [
        ("judge", "Judge"),
        ("scorer", "Scorer"),
        ("tabulator", "Tabulator"),
    ]

    code = models.CharField(max_length=32, unique=True, editable=False)
    role = models.CharField(max_length=20, choices=ROLE_CHOICES)
    label = models.CharField(
        max_length=100,
        blank=True,
        help_text="Optional display name, e.g. 'Judge Station 1'.",
    )
    user = models.OneToOneField(
        settings.AUTH_USER_MODEL,
        on_delete=models.CASCADE,
        related_name="access_code",
        null=True,
        blank=True,
    )
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = "accounts_access_code"
        ordering = ["-created_at"]

    def __str__(self):
        label = self.label or self.get_role_display()
        return f"{label} ({self.code})"

    def save(self, *args, **kwargs):
        if not self.code:
            self.code = secrets.token_hex(4).upper()

        if self.user_id is None:
            username = f"{self.role}_{self.code.lower()}"
            user = User.objects.create_user(
                username=username,
                email=f"{username}@access.eventtab.local",
                password=secrets.token_urlsafe(24),
            )
            if self.role == "judge":
                group, _ = Group.objects.get_or_create(name="Judge")
                user.groups.add(group)
            elif self.role == "tabulator":
                group, _ = Group.objects.get_or_create(name="Tabulator")
                user.groups.add(group)
            elif self.role == "scorer":
                group, _ = Group.objects.get_or_create(name="Scorer")
                user.groups.add(group)
            self.user = user

        super().save(*args, **kwargs)
