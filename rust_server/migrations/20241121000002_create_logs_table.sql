-- migrations/20241121000002_create_logs_table.sql
CREATE TYPE log_level AS ENUM ('debug', 'info', 'warning', 'error', 'critical');

CREATE TABLE logs (
    id TEXT PRIMARY KEY,
    level log_level NOT NULL,
    message TEXT NOT NULL,
    component TEXT NOT NULL,
    server_id TEXT REFERENCES servers(id),
    timestamp TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    metadata JSONB,
    stack_trace TEXT,
    source_location TEXT,
    correlation_id TEXT,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 로그 조회를 위한 인덱스
CREATE INDEX idx_logs_timestamp ON logs(timestamp DESC);
CREATE INDEX idx_logs_level ON logs(level);
CREATE INDEX idx_logs_server_id ON logs(server_id);
CREATE INDEX idx_logs_component ON logs(component);

-- Full text search를 위한 설정
ALTER TABLE logs ADD COLUMN message_tsv tsvector 
    GENERATED ALWAYS AS (to_tsvector('english', message)) STORED;
CREATE INDEX idx_logs_message_tsv ON logs USING GIN(message_tsv);

-- TimescaleDB 하이퍼테이블 생성
SELECT create_hypertable('logs', 'timestamp');

-- 보관 정책 설정 (30일)
SELECT add_retention_policy('logs', INTERVAL '30 days');