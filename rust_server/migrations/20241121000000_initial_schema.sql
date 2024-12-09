-- migrations/20241121000000_initial_schema.sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Enum types
DO $$ BEGIN
    -- OS type (서버의 운영체제 타입)
    CREATE TYPE server_type AS ENUM ('linux', 'macos', 'windows');
    
    -- Server category (서버의 물리적 타입)
    CREATE TYPE server_category AS ENUM ('physical', 'virtual', 'container');
    
    -- 기존 enum들
    CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'critical');
    CREATE TYPE user_role AS ENUM ('admin', 'user', 'viewer');
    CREATE TYPE metric_type AS ENUM ('cpu', 'memory', 'disk', 'network');
    CREATE TYPE auth_provider AS ENUM ('email', 'google', 'apple', 'kakao', 'facebook');
    CREATE TYPE log_level AS ENUM ('debug', 'info', 'warning', 'alert', 'critical');
EXCEPTION 
    WHEN duplicate_object THEN 
        NULL; -- 이미 존재하면 무시
END $$;

-- Users table
CREATE TABLE IF NOT EXISTS users (
    id VARCHAR(36) PRIMARY KEY,
    email VARCHAR(255) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    role user_role NOT NULL DEFAULT 'user',
    active BOOLEAN NOT NULL DEFAULT true,
    last_login_at TIMESTAMPTZ,
    provider auth_provider NOT NULL DEFAULT 'email',
    profile_image_url TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    hostname VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45),
    port INTEGER NOT NULL,
    username VARCHAR(255) NOT NULL,
    encrypted_password TEXT NOT NULL,
    location VARCHAR(255) DEFAULT 'Unknown',
    description TEXT,
    server_type server_type NOT NULL DEFAULT 'linux',
    server_category server_category NOT NULL DEFAULT 'physical', -- 새로 추가
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_by VARCHAR(36) REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Add server connection index
CREATE INDEX IF NOT EXISTS idx_servers_hostname_port ON servers(hostname, port);

-- Metrics snapshots
CREATE TABLE IF NOT EXISTS metrics_snapshots (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    cpu_usage DOUBLE PRECISION NOT NULL,
    memory_usage DOUBLE PRECISION NOT NULL,
    disk_usage DOUBLE PRECISION NOT NULL,
    network_rx BIGINT NOT NULL,
    network_tx BIGINT NOT NULL,
    processes JSONB NOT NULL,
    metadata JSONB DEFAULT '{}',
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT metrics_cpu_usage_check CHECK (cpu_usage >= 0 AND cpu_usage <= 100),
    CONSTRAINT metrics_memory_usage_check CHECK (memory_usage >= 0 AND memory_usage <= 100),
    CONSTRAINT metrics_disk_usage_check CHECK (disk_usage >= 0 AND disk_usage <= 100)
);

-- Create metrics timestamps index
CREATE INDEX IF NOT EXISTS idx_metrics_server_time ON metrics_snapshots(server_id, timestamp);
CREATE INDEX IF NOT EXISTS idx_metrics_server_timestamp ON metrics_snapshots(server_id, timestamp DESC);

-- Alerts table
CREATE TABLE IF NOT EXISTS alerts (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    alert_type VARCHAR(50) NOT NULL,
    severity alert_severity NOT NULL,
    message TEXT NOT NULL,
    details JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    acknowledged_at TIMESTAMPTZ,
    acknowledged_by VARCHAR(36) REFERENCES users(id),
    resolved_at TIMESTAMPTZ,
    resolved_by VARCHAR(36) REFERENCES users(id),
    resolution_note TEXT
);

-- Alert thresholds
CREATE TABLE IF NOT EXISTS alert_thresholds (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    metric_type metric_type NOT NULL,
    warning_threshold FLOAT NOT NULL,
    critical_threshold FLOAT NOT NULL,
    created_by VARCHAR(36) REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    UNIQUE (server_id, metric_type)
);

-- Maintenance windows
CREATE TABLE IF NOT EXISTS maintenance_windows (
    id BIGSERIAL PRIMARY KEY,
    server_id VARCHAR(36) NOT NULL REFERENCES servers(id) ON DELETE CASCADE,
    start_time TIMESTAMPTZ NOT NULL,
    end_time TIMESTAMPTZ NOT NULL,
    description TEXT NOT NULL,
    created_by VARCHAR(36) REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT valid_timerange CHECK (start_time < end_time)
);

-- Logs table
CREATE TABLE IF NOT EXISTS logs (
    id TEXT PRIMARY KEY,
    level log_level NOT NULL,
    message TEXT NOT NULL,
    component TEXT NOT NULL,
    server_id TEXT REFERENCES servers(id),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    metadata JSONB,
    stack_trace TEXT,
    source_location TEXT,
    correlation_id TEXT
);

-- Add log indices
CREATE INDEX IF NOT EXISTS idx_logs_level ON logs(level);
CREATE INDEX IF NOT EXISTS idx_logs_server_id ON logs(server_id);
CREATE INDEX IF NOT EXISTS idx_logs_component ON logs(component);

-- Add text search for logs
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT FROM pg_attribute
        WHERE attrelid = 'logs'::regclass
        AND attname = 'message_tsv'
        AND NOT attisdropped
    ) THEN
        ALTER TABLE logs ADD COLUMN message_tsv tsvector 
            GENERATED ALWAYS AS (to_tsvector('english', message)) STORED;
    END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_logs_message_tsv ON logs USING GIN(message_tsv);

-- Audit logs
CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id),
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50) NOT NULL,
    entity_id VARCHAR(255) NOT NULL,
    changes JSONB NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Token blacklist
CREATE TABLE IF NOT EXISTS token_blacklist (
    token_id TEXT PRIMARY KEY,
    user_id VARCHAR(36) REFERENCES users(id),
    blacklisted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL
);

-- User sessions table
CREATE TABLE IF NOT EXISTS user_sessions (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    session_token TEXT NOT NULL,
    ip_address VARCHAR(45),
    user_agent TEXT,
    last_active_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uk_user_session_token UNIQUE (session_token)
);

-- Refresh tokens table
CREATE TABLE IF NOT EXISTS refresh_tokens (
    id BIGSERIAL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token TEXT NOT NULL,
    issued_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMPTZ NOT NULL,
    revoked_at TIMESTAMPTZ,
    replaced_by TEXT,
    CONSTRAINT uk_refresh_token UNIQUE (token)
);

-- Additional indexes
CREATE INDEX IF NOT EXISTS idx_alerts_server_created ON alerts(server_id, created_at);
CREATE INDEX IF NOT EXISTS idx_alerts_unacknowledged ON alerts(acknowledged_at) WHERE acknowledged_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_maintenance_timerange ON maintenance_windows(server_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_token_blacklist_expires ON token_blacklist(expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_user ON user_sessions(user_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_user_sessions_token ON user_sessions(session_token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user ON refresh_tokens(user_id, expires_at);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_token ON refresh_tokens(token);
CREATE INDEX IF NOT EXISTS idx_refresh_tokens_revoked ON refresh_tokens(revoked_at) WHERE revoked_at IS NOT NULL;

-- Update timestamp trigger function
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Create triggers
DROP TRIGGER IF EXISTS update_servers_modtime ON servers;
CREATE TRIGGER update_servers_modtime
    BEFORE UPDATE ON servers
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_users_modtime ON users;
CREATE TRIGGER update_users_modtime
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_alert_thresholds_modtime ON alert_thresholds;
CREATE TRIGGER update_alert_thresholds_modtime
    BEFORE UPDATE ON alert_thresholds
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

DROP TRIGGER IF EXISTS update_maintenance_windows_modtime ON maintenance_windows;
CREATE TRIGGER update_maintenance_windows_modtime
    BEFORE UPDATE ON maintenance_windows
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Cleanup triggers
CREATE OR REPLACE FUNCTION cleanup_expired_sessions()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM user_sessions WHERE expires_at < CURRENT_TIMESTAMP;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cleanup_expired_sessions ON user_sessions;
CREATE TRIGGER trigger_cleanup_expired_sessions
    AFTER INSERT ON user_sessions
    EXECUTE FUNCTION cleanup_expired_sessions();

CREATE OR REPLACE FUNCTION cleanup_expired_refresh_tokens()
RETURNS TRIGGER AS $$
BEGIN
    DELETE FROM refresh_tokens 
    WHERE expires_at < CURRENT_TIMESTAMP 
    OR revoked_at IS NOT NULL;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_cleanup_expired_refresh_tokens ON refresh_tokens;
CREATE TRIGGER trigger_cleanup_expired_refresh_tokens
    AFTER INSERT ON refresh_tokens
    EXECUTE FUNCTION cleanup_expired_refresh_tokens();

-- Insert default admin user if not exists
INSERT INTO users (
    id, email, password_hash, name, role, active, created_at, updated_at
) VALUES (
    uuid_generate_v4(),
    'admin@example.com',
    -- Default password: 'admin123' (change in production)
    '$2b$12$LQv3c1yqBWVHxkd0LHAkCOYz6TtxMQJqhN8/LewdBPj6f.CbP0pjm',
    'System Admin',
    'admin',
    true,
    CURRENT_TIMESTAMP,
    CURRENT_TIMESTAMP
) ON CONFLICT (email) DO NOTHING;