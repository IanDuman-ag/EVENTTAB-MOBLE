from django.contrib.auth.models import AbstractUser
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
