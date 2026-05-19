"""
execution/test_email.py
------------------------
Sends a test email to verify SMTP configuration.

Usage:
    python execution/test_email.py recipient@example.com

Environment variables (from backend/.env):
    EMAIL_BACKEND, EMAIL_HOST, EMAIL_PORT, etc.
"""

import os
import sys

if len(sys.argv) < 2:
    print("Usage: python execution/test_email.py recipient@example.com")
    sys.exit(1)

recipient = sys.argv[1]

sys.path.insert(0, "backend")
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "eventtab_backend.settings")

import django

django.setup()

from django.core.mail import send_mail
from django.conf import settings

print(f"Sending test email to {recipient} ...")
print(f"Using backend: {settings.EMAIL_BACKEND}")
print(f"SMTP host: {settings.EMAIL_HOST}:{settings.EMAIL_PORT}")
print()

try:
    send_mail(
        subject="Eventtab - Test Email",
        message="""Hello,

This is a test email from Eventtab to verify your SMTP configuration is working.

If you received this, everything is set up correctly!

— Eventtab Team
""",
        from_email=settings.DEFAULT_FROM_EMAIL,
        recipient_list=[recipient],
        fail_silently=False,
    )
    print("✓ Email sent successfully!")
    print()
    if settings.EMAIL_BACKEND == "django.core.mail.backends.console.EmailBackend":
        print("Note: You're using the console backend, so the email was printed above")
        print("instead of actually sent. To send real emails, configure EMAIL_BACKEND")
        print("in your .env file. See directives/email_setup.md for details.")
except Exception as e:
    print(f"✗ Failed to send email: {e}")
    sys.exit(1)
