-- migrations/20241121000001_setup_timescale_policies.sql

-- 인증 제공자 enum 타입 생성
CREATE TYPE auth_provider AS ENUM ('email', 'google', 'apple', 'kakao', 'facebook');

-- users 테이블 수정
ALTER TABLE users
    ALTER COLUMN password_hash DROP NOT NULL,
    ALTER COLUMN provider TYPE auth_provider USING provider::auth_provider,
    ADD COLUMN profile_image_url TEXT,
    ADD COLUMN last_login_at TIMESTAMPTZ;

-- provider에 대한 인덱스 추가
CREATE INDEX idx_users_provider ON users(provider);