-- migrations/20241129000004_add_auth_provider.sql
DO $$ BEGIN
    CREATE TYPE auth_provider AS ENUM ('email', 'google', 'apple', 'kakao', 'facebook');
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

ALTER TABLE users 
    ADD COLUMN IF NOT EXISTS provider auth_provider NOT NULL DEFAULT 'email',
    ADD COLUMN IF NOT EXISTS profile_image_url TEXT,
    ALTER COLUMN password_hash DROP NOT NULL;