# Directive: Flutter App Setup

## Goal
Run the Eventtab Flutter app against the local Django backend.

## Prerequisites
- Flutter SDK (see `pubspec.yaml` for SDK constraint: `^3.11.0`)
- Backend running at `http://127.0.0.1:8000` (see `directives/backend_setup.md`)

## Run the app
```bash
flutter run
```

To point at a different backend:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.x:8000
```

## App structure

| File | Purpose |
|------|---------|
| `lib/main.dart` | App entry, routing, `BackendStatusPage` |
| `lib/config.dart` | App-wide configuration (API base URL, etc.) |
| `lib/auth_service.dart` | HTTP auth layer, `AuthSession` |
| `lib/login.dart` | Login screen |
| `lib/signin.dart` | Create account screen |
| `lib/forgotpass.dart` | Forgot / reset password screen |
| `lib/home.dart` | Home screen (post-login) |
| `lib/schedule.dart` | Schedule / calendar view |
| `lib/bracket.dart` | Tournament bracket view |
| `lib/rankings.dart` | Rankings / leaderboard view |
| `lib/teams.dart` | Teams management view |
| `lib/terms.dart` | Terms & conditions screen |

## Auth flow
1. User opens app → `LoginPage`
2. Login → `authService.login()` → token stored in `AuthSession`
3. Create account → `authService.register()` → auto-logged in
4. Forgot password → `ForgotPasswordPage` (2-step: request token → set new password)
5. After login → Home screen

## Learnings
_(update this section as you discover Flutter-specific issues)_
