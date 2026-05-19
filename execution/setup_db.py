"""
execution/setup_db.py
----------------------
Creates the PostgreSQL database and user for local development.
Requires a PostgreSQL superuser (e.g. 'postgres').

Usage:
    python execution/setup_db.py

Environment variables:
    PG_SUPERUSER      — defaults to postgres
    PG_SUPERPASSWORD  — defaults to (empty)
    PG_HOST           — defaults to 127.0.0.1
    PG_PORT           — defaults to 5432
    DB_NAME           — defaults to eventtabs
    DB_USER           — defaults to event_users
    DB_PASSWORD       — defaults to event_pass
"""

import os
import sys

try:
    import psycopg2
    from psycopg2 import sql
    from psycopg2.extensions import ISOLATION_LEVEL_AUTOCOMMIT
except ImportError:
    print("psycopg2 not installed. Run: pip install psycopg2-binary", file=sys.stderr)
    sys.exit(1)

# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

PG_SUPERUSER = os.getenv("PG_SUPERUSER", "postgres")
PG_SUPERPASSWORD = os.getenv("PG_SUPERPASSWORD", "")
PG_HOST = os.getenv("PG_HOST", "127.0.0.1")
PG_PORT = int(os.getenv("PG_PORT", "5432"))

DB_NAME = os.getenv("DB_NAME", "eventtabs")
DB_USER = os.getenv("DB_USER", "event_users")
DB_PASSWORD = os.getenv("DB_PASSWORD", "event_pass")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    print(f"Connecting to PostgreSQL as '{PG_SUPERUSER}' at {PG_HOST}:{PG_PORT} ...")

    conn = psycopg2.connect(
        host=PG_HOST,
        port=PG_PORT,
        user=PG_SUPERUSER,
        password=PG_SUPERPASSWORD,
        dbname="postgres",
    )
    conn.set_isolation_level(ISOLATION_LEVEL_AUTOCOMMIT)
    cur = conn.cursor()

    # Create user if not exists
    cur.execute(
        "SELECT 1 FROM pg_roles WHERE rolname = %s",
        (DB_USER,),
    )
    if cur.fetchone():
        print(f"  ℹ Role '{DB_USER}' already exists — skipping.")
    else:
        cur.execute(
            sql.SQL("CREATE USER {} WITH PASSWORD %s").format(
                sql.Identifier(DB_USER)
            ),
            (DB_PASSWORD,),
        )
        print(f"  ✓ Created role '{DB_USER}'.")

    # Create database if not exists
    cur.execute(
        "SELECT 1 FROM pg_database WHERE datname = %s",
        (DB_NAME,),
    )
    if cur.fetchone():
        print(f"  ℹ Database '{DB_NAME}' already exists — skipping.")
    else:
        cur.execute(
            sql.SQL("CREATE DATABASE {} OWNER {}").format(
                sql.Identifier(DB_NAME),
                sql.Identifier(DB_USER),
            )
        )
        print(f"  ✓ Created database '{DB_NAME}'.")

    # Grant privileges
    cur.execute(
        sql.SQL("GRANT ALL PRIVILEGES ON DATABASE {} TO {}").format(
            sql.Identifier(DB_NAME),
            sql.Identifier(DB_USER),
        )
    )
    print(f"  ✓ Granted privileges on '{DB_NAME}' to '{DB_USER}'.")

    cur.close()
    conn.close()

    print()
    print("Done. Next steps:")
    print("  1. Copy backend/.env.example to backend/.env and verify DB_* values.")
    print("  2. python backend/manage.py migrate")
    print("  3. python execution/seed_test_user.py")


if __name__ == "__main__":
    main()
