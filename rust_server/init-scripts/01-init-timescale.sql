-- init-scripts/01-init-timescale.sql
-- First, create TimescaleDB extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "timescaledb";

-- Create metrics_snapshots table first
CREATE TABLE IF NOT EXISTS metrics_snapshots (
    id BIGSERIAL,
    server_id TEXT NOT NULL,
    cpu_usage DOUBLE PRECISION NOT NULL,
    memory_usage DOUBLE PRECISION NOT NULL,
    disk_usage DOUBLE PRECISION NOT NULL,
    network_rx BIGINT NOT NULL,
    network_tx BIGINT NOT NULL,
    processes JSONB NOT NULL,
    timestamp TIMESTAMPTZ NOT NULL,
    PRIMARY KEY (id, timestamp)
);

-- Then create hypertable
SELECT create_hypertable('metrics_snapshots', 'timestamp',
    chunk_time_interval => INTERVAL '1 day',
    if_not_exists => TRUE
);

-- Create retention policy (keep data for 30 days)
SELECT add_retention_policy('metrics_snapshots', INTERVAL '30 days');

-- Enable compression first
ALTER TABLE metrics_snapshots SET (
    timescaledb.compress,
    timescaledb.compress_segmentby = 'server_id,id',  -- id 추가
    timescaledb.compress_orderby = 'timestamp DESC'
);

-- Then add compression policy
SELECT add_compression_policy('metrics_snapshots', INTERVAL '1 day');

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_metrics_server_timestamp 
ON metrics_snapshots (server_id, timestamp DESC);