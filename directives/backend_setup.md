# Directive: Backend Setup

## Goal
Get the Django backend running locally with a PostgreSQL database.

## Prerequisites
- Python 3.11+
- PostgreSQL running on localhost:5432
- A virtual environment at `venv/`

## Steps

### 1. Install dependencies
```bash
cd backend
pip install -r requirements.txt
```

### 2. Configure environment
Copy `.env.example` to `.env` and fill in your values:
```bash
cp backend/.env.example backend/.env
```

Key variables:
- `SECRET_KEY` — any random string for local dev
- `DB_NAME`, `DB_USER`, `DB_PASSWORD` — must match your PostgreSQL setup
- `DJANGO_DEBUG=True` — enables debug mode (returns reset tokens in responses)

### 3. Create the database
```sql
CREATE DATABASE eventtabs;
CREATE USER event_users WITH PASSWORD 'event_pass';
GRANT ALL PRIVILEGES ON DATABASE eventtabs TO event_users;
```

### 4. Run migrations
```bash
python backend/manage.py migrate
```

### 5. Start the server
```bash
python backend/manage.py runserver
```

## Scripts
- `execution/setup_db.py` — creates the database and user (requires superuser credentials)
- `execution/seed_test_user.py` — seeds a test user for Flutter development

## Learnings
_(update this section as you discover setup issues)_
