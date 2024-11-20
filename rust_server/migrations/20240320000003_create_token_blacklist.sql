-- rust_server/migrations/20240320000003_create_token_blacklist.sql
CREATE TABLE IF NOT EXISTS token_blacklist (
    token_id TEXT PRIMARY KEY,
    blacklisted_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);