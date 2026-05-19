"""
execution/seed_test_user.py
----------------------------
Creates a test user in the database via the Django auth API.
Run this after `python backend/manage.py migrate` to get a user you can
log in with immediately during Flutter development.

Usage:
    python execution/seed_test_user.py

Environment variables (from backend/.env or shell):
    API_BASE_URL  — defaults to http://127.0.0.1:8000
    TEST_USERNAME — defaults to testuser
    TEST_EMAIL    — defaults to test@eventtab.dev
    TEST_PASSWORD — defaults to TestPass123!
"""

import json
import os
import sys
import urllib.request
import urllib.error

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

BASE_URL = os.getenv("API_BASE_URL", "http://127.0.0.1:8000")
USERNAME = os.getenv("TEST_USERNAME", "testuser")
EMAIL = os.getenv("TEST_EMAIL", "test@eventtab.dev")
PASSWORD = os.getenv("TEST_PASSWORD", "TestPass123!")

REGISTER_URL = f"{BASE_URL}/api/auth/register/"


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def post_json(url: str, payload: dict) -> tuple[int, dict]:
    """Send a JSON POST and return (status_code, response_body)."""
    data = json.dumps(payload).encode("utf-8")
    req = urllib.request.Request(
        url,
        data=data,
        headers={"Content-Type": "application/json", "Accept": "application/json"},
        method="POST",
    )
    try:
        with urllib.request.urlopen(req) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as exc:
        body = {}
        try:
            body = json.loads(exc.read())
        except Exception:
            pass
        return exc.code, body


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print(f"Seeding test user '{USERNAME}' at {REGISTER_URL} ...")

    status, body = post_json(
        REGISTER_URL,
        {
            "username": USERNAME,
            "email": EMAIL,
            "password": PASSWORD,
            "confirm_password": PASSWORD,
        },
    )

    if status == 201:
        token = body.get("token", "")
        user = body.get("user", {})
        print(f"  ✓ Created user id={user.get('id')} username={user.get('username')}")
        print(f"  ✓ Token: {token}")
        print()
        print("Login credentials:")
        print(f"  Username : {USERNAME}")
        print(f"  Email    : {EMAIL}")
        print(f"  Password : {PASSWORD}")
    elif status == 400:
        # Username/email already exists — that's fine
        errors = body
        if any(
            "already" in str(v).lower()
            for v in errors.values()
        ):
            print(f"  ℹ User '{USERNAME}' already exists — nothing to do.")
        else:
            print(f"  ✗ Validation error: {errors}", file=sys.stderr)
            sys.exit(1)
    else:
        print(f"  ✗ Unexpected status {status}: {body}", file=sys.stderr)
        sys.exit(1)


if __name__ == "__main__":
    main()
