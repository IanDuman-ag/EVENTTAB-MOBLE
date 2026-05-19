"""
Drops all tables in the public schema and re-runs all migrations.
Safe for local dev only.
"""
import os, sys
sys.path.insert(0, 'backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'eventtab_backend.settings')
import django; django.setup()
from django.db import connection

print("Dropping all tables in public schema...")
with connection.cursor() as cur:
    cur.execute("""
        DO $$ DECLARE
            r RECORD;
        BEGIN
            FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = 'public') LOOP
                EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
        END $$;
    """)
print("Done. All tables dropped.")
print("Now run: .\\venv\\Scripts\\python.exe backend\\manage.py migrate")
