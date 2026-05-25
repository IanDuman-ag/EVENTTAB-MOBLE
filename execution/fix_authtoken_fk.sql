-- Fix: authtoken_token foreign key was pointing to auth_user instead of accounts_user.
-- Run this once if you see:
--   "insert or update on table authtoken_token violates foreign key constraint
--    authtoken_token_user_id_auth_user_fk"
--
-- Usage (from backend/ directory):
--   $env:PGPASSWORD='event_pass'
--   psql -U event_users -d eventtabs -h 127.0.0.1 -f ../execution/fix_authtoken_fk.sql

ALTER TABLE authtoken_token
    DROP CONSTRAINT IF EXISTS authtoken_token_user_id_auth_user_fk;

ALTER TABLE authtoken_token
    DROP CONSTRAINT IF EXISTS authtoken_token_user_id_accounts_user_fk;

ALTER TABLE authtoken_token
    ADD CONSTRAINT authtoken_token_user_id_accounts_user_fk
    FOREIGN KEY (user_id) REFERENCES accounts_user(id) ON DELETE CASCADE;
