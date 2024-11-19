-- migrations/20240320000001_update_enum_types.sql

-- 기존 enum 타입 삭제
DROP TYPE IF EXISTS server_type CASCADE;
DROP TYPE IF EXISTS alert_severity CASCADE;
DROP TYPE IF EXISTS user_role CASCADE;

-- 새로운 enum 타입 정의
CREATE TYPE server_type AS ENUM ('physical', 'virtual', 'container');
CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'critical');
CREATE TYPE user_role AS ENUM ('admin', 'user', 'viewer');

-- 테이블 컬럼 타입 변경
ALTER TABLE metrics_snapshots
    ALTER COLUMN cpu_usage TYPE double precision,
    ALTER COLUMN memory_usage TYPE double precision,
    ALTER COLUMN disk_usage TYPE double precision;