import os, sys
sys.path.insert(0, 'backend')
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'eventtab_backend.settings')
import django; django.setup()
from django.db import connection
with connection.cursor() as cur:
    cur.execute("SELECT tablename FROM pg_tables WHERE schemaname = 'public' ORDER BY tablename")
    for row in cur.fetchall():
        print(row[0])
