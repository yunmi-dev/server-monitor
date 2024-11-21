-- migrations/20241121000000_initial_schema.sql
-- Enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- Enum types
DO $$ BEGIN
    CREATE TYPE server_type AS ENUM ('physical', 'virtual', 'container');
    CREATE TYPE alert_severity AS ENUM ('info', 'warning', 'critical');
    CREATE TYPE user_role AS ENUM ('admin', 'user', 'viewer');
    CREATE TYPE metric_type AS ENUM ('cpu', 'memory', 'disk', 'network');
EXCEPTION
    WHEN duplicate_object THEN NULL;
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
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Servers table
CREATE TABLE IF NOT EXISTS servers (
    id VARCHAR(36) PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    hostname VARCHAR(255) NOT NULL UNIQUE,
    ip_address VARCHAR(45) NOT NULL,
    location VARCHAR(255) NOT NULL,
    description TEXT,
    server_type server_type NOT NULL,
    is_online BOOLEAN NOT NULL DEFAULT false,
    last_seen_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_by VARCHAR(36) REFERENCES users(id),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP
);

-- Metrics snapshots
CREATE TABLE IF NOT EXISTS metrics_snapshots (
    id BIGSERIAL,
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
    CONSTRAINT metrics_disk_usage_check CHECK (disk_usage >= 0 AND disk_usage <= 100),
    PRIMARY KEY (id, timestamp)
);

-- Convert to hypertable
SELECT create_hypertable('metrics_snapshots', 'timestamp', if_not_exists => TRUE);

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

-- Indexes
CREATE INDEX IF NOT EXISTS idx_metrics_server_timestamp ON metrics_snapshots(server_id, timestamp DESC);
CREATE INDEX IF NOT EXISTS idx_alerts_server_created ON alerts(server_id, created_at);
CREATE INDEX IF NOT EXISTS idx_alerts_unacknowledged ON alerts(acknowledged_at) WHERE acknowledged_at IS NULL;
CREATE INDEX IF NOT EXISTS idx_maintenance_timerange ON maintenance_windows(server_id, start_time, end_time);
CREATE INDEX IF NOT EXISTS idx_audit_logs_user ON audit_logs(user_id, created_at);
CREATE INDEX IF NOT EXISTS idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_token_blacklist_expires ON token_blacklist(expires_at);

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