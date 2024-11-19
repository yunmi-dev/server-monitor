-- migrations/20240320000000_update_metrics_for_timescale.sql


-- Drop existing table and related objects
DROP TABLE IF EXISTS metrics_snapshots CASCADE;

-- Alter existing tables to use TEXT type
ALTER TABLE servers ALTER COLUMN id TYPE TEXT;
ALTER TABLE alerts ALTER COLUMN server_id TYPE TEXT;
ALTER TABLE alert_thresholds ALTER COLUMN server_id TYPE TEXT;

-- Recreate metrics_snapshots table with TimescaleDB optimized structure
CREATE TABLE metrics_snapshots (
    id BIGSERIAL,
    timestamp TIMESTAMPTZ NOT NULL,
    server_id TEXT NOT NULL,
    cpu_usage FLOAT NOT NULL,
    memory_usage FLOAT NOT NULL,
    disk_usage FLOAT NOT NULL,
    network_rx BIGINT NOT NULL,
    network_tx BIGINT NOT NULL,
    processes JSONB NOT NULL,
    PRIMARY KEY (id, timestamp),
    CONSTRAINT metrics_cpu_usage_check CHECK (cpu_usage >= 0 AND cpu_usage <= 100),
    CONSTRAINT metrics_memory_usage_check CHECK (memory_usage >= 0 AND memory_usage <= 100),
    CONSTRAINT metrics_disk_usage_check CHECK (disk_usage >= 0 AND disk_usage <= 100),
    CONSTRAINT fk_server FOREIGN KEY (server_id) REFERENCES servers(id) ON DELETE CASCADE
);

-- Create index
CREATE INDEX idx_metrics_server_timestamp ON metrics_snapshots(server_id, timestamp DESC);

-- Create hypertable
SELECT create_hypertable('metrics_snapshots', 'timestamp', if_not_exists => TRUE);

-- Optional: Configure compression
ALTER TABLE metrics_snapshots SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'server_id'
);

-- Optional: Add compression policy
SELECT add_compression_policy('metrics_snapshots', INTERVAL '7 days');