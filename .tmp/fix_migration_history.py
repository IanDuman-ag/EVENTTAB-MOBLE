"""
Inserts accounts.0001_initial into django_migrations so Django stops
complaining about inconsistent history, then creates the accounts_user
table without touching any existing tables.

Safe: only INSERTs into django_migrations and CREATEs new tables.
"""
import os, sys
sys.path.insert(0, 'backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'eventtab_backend.settings')
import django; django.setup()
from django.db import connection
from django.utils import timezone

with connection.cursor() as cur:
    # 1. Check if the record already exists
    cur.execute(
        "SELECT 1 FROM django_migrations WHERE app = %s AND name = %s",
        ['accounts', '0001_initial'],
    )
    if cur.fetchone():
        print("accounts.0001_initial already in django_migrations — nothing to do.")
    else:
        cur.execute(
            "INSERT INTO django_migrations (app, name, applied) VALUES (%s, %s, %s)",
            ['accounts', '0001_initial', timezone.now()],
        )
        print("Inserted accounts.0001_initial into django_migrations.")

    # 2. Create accounts_user table if it doesn't exist
    cur.execute("""
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'accounts_user'
    """)
    if cur.fetchone():
        print("accounts_user table already exists — skipping CREATE.")
    else:
        cur.execute("""
            CREATE TABLE accounts_user (
                id          BIGSERIAL PRIMARY KEY,
                password    VARCHAR(128)  NOT NULL,
                last_login  TIMESTAMPTZ,
                is_superuser BOOLEAN      NOT NULL DEFAULT FALSE,
                username    VARCHAR(150)  NOT NULL UNIQUE,
                first_name  VARCHAR(150)  NOT NULL DEFAULT '',
                last_name   VARCHAR(150)  NOT NULL DEFAULT '',
                email       VARCHAR(254)  NOT NULL UNIQUE,
                is_staff    BOOLEAN       NOT NULL DEFAULT FALSE,
                is_active   BOOLEAN       NOT NULL DEFAULT TRUE,
                date_joined TIMESTAMPTZ   NOT NULL DEFAULT NOW()
            )
        """)
        print("Created accounts_user table.")

    # 3. Create the M2M junction tables Django expects
    cur.execute("""
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'accounts_user_groups'
    """)
    if not cur.fetchone():
        cur.execute("""
            CREATE TABLE accounts_user_groups (
                id       BIGSERIAL PRIMARY KEY,
                user_id  BIGINT NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
                group_id INTEGER NOT NULL REFERENCES auth_group(id) ON DELETE CASCADE,
                UNIQUE (user_id, group_id)
            )
        """)
        print("Created accounts_user_groups table.")

    cur.execute("""
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = 'accounts_user_user_permissions'
    """)
    if not cur.fetchone():
        cur.execute("""
            CREATE TABLE accounts_user_user_permissions (
                id            BIGSERIAL PRIMARY KEY,
                user_id       BIGINT  NOT NULL REFERENCES accounts_user(id) ON DELETE CASCADE,
                permission_id INTEGER NOT NULL REFERENCES auth_permission(id) ON DELETE CASCADE,
                UNIQUE (user_id, permission_id)
            )
        """)
        print("Created accounts_user_user_permissions table.")

print("\nDone. Now run: .\\venv\\Scripts\\python.exe backend\\manage.py migrate")
