# Directive: Authentication

## Goal
Manage user registration, login, logout, and password reset against the Django backend.

## Endpoints

| Method | Path | Auth required | Description |
|--------|------|---------------|-------------|
| POST | `/api/auth/register/` | No | Create account |
| POST | `/api/auth/login/` | No | Login (username or email) |
| POST | `/api/auth/logout/` | Token | Invalidate token |
| POST | `/api/auth/forgot-password/` | No | Request reset token |
| POST | `/api/auth/reset-password/` | No | Set new password |
| GET  | `/api/auth/me/` | Token | Current user info |

## Inputs
- `register`: `{ username, email, password, confirm_password }`
- `login`: `{ identifier, password }` — identifier is username or email
- `forgot-password`: `{ email }`
- `reset-password`: `{ reset_token, new_password, confirm_password }`

## Outputs
- `register` / `login`: `{ token, user: { id, username, email } }`
- `forgot-password`: `{ detail }` — reset code is sent via email
- `reset-password`: `{ detail }`

## Token storage
Currently in-memory (`AuthSession` in `lib/auth_service.dart`).
Upgrade path: `flutter_secure_storage` for persistent sessions.

## Edge cases
- Forgot-password always returns 200 regardless of whether the email exists (prevents enumeration).
- Reset codes expire after **2 minutes** (Django cache TTL).
- Users can request a new code if the old one expires (generates a fresh token).
- Reset codes are sent via email. By default (console backend), they print to the Django terminal for easy dev testing.
- Resetting a password invalidates all existing auth tokens for that user.

## Scripts
- `execution/seed_test_user.py` — creates a test user in the database

## Learnings
_(update this section as you discover API constraints or edge cases)_
