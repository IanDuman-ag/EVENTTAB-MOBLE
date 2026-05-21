import psycopg2

conn = psycopg2.connect(
    dbname='eventtabs',
    user='event_users',
    password='event_pass',
    host='127.0.0.1',
    port='5432'
)
cur = conn.cursor()
cur.execute("SELECT tablename FROM pg_tables WHERE schemaname='public' ORDER BY tablename")
tables = cur.fetchall()
print("Tables in database:")
for table in tables:
    print(f"  - {table[0]}")
conn.close()
