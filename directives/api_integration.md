# API Integration Reference — Eventtab

## How to run the backend

```bash
# Always run from the backend/ subdirectory, NOT the project root
cd backend
python manage.py runserver
```

The server starts at `http://127.0.0.1:8000`.

---

## Architecture

```
Flutter App  ──HTTP──►  Django REST API  ──ORM──►  PostgreSQL
                         (Token Auth)
```

Flutter **never** connects to PostgreSQL directly. All data flows through the Django API.

---

## Authentication

All endpoints (except login/register/forgot-password) require:

```
Authorization: Token <token>
```

### Login
```
POST /api/auth/login/
Body: { "identifier": "judge1@gmail.com", "password": "Judge1" }
```
```json
{
  "token": "354bddfedfeb776173028f3d4b3f2bbb8a81841c",
  "user": { "id": 5, "username": "judge1", "email": "judge1@gmail.com" }
}
```

### Register
```
POST /api/auth/register/
Body: { "username": "...", "email": "...", "password": "...", "confirm_password": "..." }
```

### Logout
```
POST /api/auth/logout/
Header: Authorization: Token <token>
```

### Forgot Password
```
POST /api/auth/forgot-password/
Body: { "email": "user@example.com" }
```
Sends a 6-digit code to the user's email (expires in 2 minutes).

### Reset Password
```
POST /api/auth/reset-password/
Body: { "reset_token": "123456", "new_password": "...", "confirm_password": "..." }
```

---

## Event Categories

### List all categories
```
GET /api/events/categories/
```
```json
[
  {
    "id": 1,
    "name": "Academic Event",
    "category_type": "academic",
    "description": "Academic competitions",
    "icon": "school",
    "color": "#2196F3",
    "event_count": 1
  }
]
```
`category_type` values: `academic`, `esports`, `sports`, `socio_cultural`

### Events in a category
```
GET /api/events/categories/{id}/events/
```
```json
[
  {
    "id": 1,
    "title": "Mr. & Ms. USTP 2026",
    "category_name": "Socio Cultural",
    "category_type": "socio_cultural",
    "date": "2026-04-20",
    "time": "18:00:00",
    "venue": "Covered Court",
    "status": "active",
    "candidate_count": 3
  }
]
```

---

## Judging Events

### Event detail (with criteria + candidates)
```
GET /api/events/judging-events/{id}/
```
```json
{
  "id": 1,
  "title": "Mr. & Ms. USTP 2026",
  "category_name": "Socio Cultural",
  "category_type": "socio_cultural",
  "date": "2026-04-20",
  "time": "18:00:00",
  "venue": "Covered Court",
  "status": "active",
  "description": "",
  "candidate_count": 3,
  "criteria": [
    {
      "id": 1,
      "name": "Talent Portion",
      "description": "Performance",
      "max_score": "20.0",
      "weight_percent": "20.0",
      "order": 1
    }
  ],
  "candidates": [
    { "id": 1, "name": "Leborn James", "number": 1, "photo": null, "description": "" }
  ]
}
```

### Standings / Rankings
```
GET /api/events/judging-events/{id}/standings/
```
```json
[
  {
    "rank": 1,
    "candidate_id": 2,
    "name": "Maria Santos",
    "number": 2,
    "total_score": "44.00",
    "is_live": false
  }
]
```
Sorted by `total_score` descending. Score formula: `sum(score * weight_percent / max_score)`.

### My scores (check if already submitted)
```
GET /api/events/judging-events/{id}/my_scores/?candidate_id={candidate_id}
```
Returns `[]` if no scores yet, or a list with `is_locked: true` if already submitted.

### Submit scores (locks permanently)
```
POST /api/events/judging-events/{id}/submit_scores/
Body:
{
  "candidate_id": 2,
  "scores": [
    { "criterion_id": 1, "score": 18 },
    { "criterion_id": 2, "score": 17 },
    { "criterion_id": 3, "score": 9 }
  ]
}
```
```json
{
  "verification_id": "2528A351-9CE1",
  "submitted_at": "2026-05-24T18:07:17.048622+00:00",
  "total_score": 44.0,
  "breakdown": [
    {
      "criterion": "Talent Portion",
      "score": 18.0,
      "max_score": 20.0,
      "weight": 20.0,
      "weighted_score": 18.0
    }
  ],
  "is_locked": true
}
```
Once submitted, scores are **permanently locked**. Re-submitting returns HTTP 400.

---

## Viewer Endpoints (Home + Rankings)

### Featured match
```
GET /api/events/matches/featured/
```

### Upcoming matches
```
GET /api/events/matches/upcoming/
```

### Activity feed
```
GET /api/events/activities/
```

### Teams
```
GET /api/events/teams/
```

---

## Flutter API Config

All Flutter files use `lib/api_config.dart`:

```dart
import '../../api_config.dart';

// Build a URI
final uri = apiUri('/api/events/categories/');

// Make an authenticated request
final res = await http.get(
  apiUri('/api/events/judging-events/$eventId/'),
  headers: {'Authorization': 'Token ${JudgeAuthSession.current?.token}'},
);
```

To point at a production server, build with:
```bash
flutter build web --dart-define=API_BASE_URL=https://your-server.com
```

---

## URL Map

| Flutter Page         | HTTP Method | Endpoint                                              |
|----------------------|-------------|-------------------------------------------------------|
| judgelogin.dart      | POST        | /api/auth/login/                                      |
| jevent.dart          | GET         | /api/events/categories/                               |
| jevent.dart          | GET         | /api/events/categories/{id}/events/                   |
| jevent_detail.dart   | GET         | /api/events/judging-events/{id}/                      |
| jscore.dart          | GET         | /api/events/judging-events/{id}/my_scores/?candidate_id=X |
| jscore.dart          | POST        | /api/events/judging-events/{id}/submit_scores/        |
| rankings.dart        | GET         | /api/events/categories/                               |
| rankings.dart        | GET         | /api/events/categories/{id}/events/                   |
| rankings.dart        | GET         | /api/events/judging-events/{id}/standings/            |
| home.dart            | GET         | /api/events/matches/featured/                         |
| home.dart            | GET         | /api/events/matches/upcoming/                         |
| home.dart            | GET         | /api/events/activities/                               |

---

## Admin — Adding Data

Go to `http://127.0.0.1:8000/admin/` and log in with a superuser account.

| Model          | What to create                                                  |
|----------------|-----------------------------------------------------------------|
| EventCategory  | Create categories (Academic, Esports, Sports, Socio Cultural)   |
| JudgingEvent   | Create events, assign to a category, set date/venue/status      |
| Criterion      | Add scoring criteria to each event (name, max_score, weight%)   |
| Candidate      | Add candidates to each event (name, number)                     |
| JudgingEvent   | Assign judges via the `assigned_judges` field                   |

**Important:** `weight_percent` values across all criteria for one event should sum to 100.

---

## Common Errors

| Error | Cause | Fix |
|-------|-------|-----|
| `authtoken_token_user_id_auth_user_fk` | FK points to wrong table | Run the SQL fix in `execution/fix_authtoken_fk.sql` |
| `can't open file manage.py` | Running from wrong directory | `cd backend` first |
| HTTP 401 on all requests | Token missing or expired | Re-login to get a fresh token |
| HTTP 400 "Scores already locked" | Judge already submitted | Expected — scores are permanent |
