-- migrations/20241121000001_setup_timescale_policies.sql
DO $$ 
BEGIN
    -- Drop existing policies if they exist
    BEGIN
        SELECT remove_compression_policy('metrics_snapshots', if_exists => TRUE);
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    BEGIN
        SELECT remove_retention_policy('metrics_snapshots', if_exists => TRUE);
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;

    -- Set up compression
    ALTER TABLE metrics_snapshots SET (
        timescaledb.compress,
        timescaledb.compress_segmentby = 'server_id'
    );

    -- Add new policies
    PERFORM add_compression_policy('metrics_snapshots', INTERVAL '7 days', if_not_exists => TRUE);
    PERFORM add_retention_policy('metrics_snapshots', INTERVAL '30 days', if_not_exists => TRUE);
EXCEPTION WHEN OTHERS THEN
    RAISE NOTICE 'Error setting up TimescaleDB policies: %', SQLERRM;
END $$;