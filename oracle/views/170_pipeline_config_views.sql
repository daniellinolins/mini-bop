PROMPT Creating pipeline configuration views...

CREATE OR REPLACE VIEW vw_pipeline_config_catalog AS
SELECT config_id,
       pipeline_code,
       pipeline_name,
       source_system,
       is_active,
       use_bulk,
       use_parallel,
       parallel_level,
       bulk_limit,
       run_reconciliation,
       run_data_quality,
       run_metadata_rules,
       run_lineage,
       metadata_rule_group,
       scheduler_job_name,
       scheduler_hour,
       created_at,
       updated_at
FROM pipeline_config;

CREATE OR REPLACE VIEW vw_pipeline_config_runs AS
SELECT r.config_run_id,
       r.pipeline_code,
       r.status,
       r.source_batch_id,
       r.orchestration_batch_id,
       r.reconciliation_batch_id,
       r.dq_batch_id,
       r.metadata_execution_id,
       r.lineage_run_id,
       r.loaded_rows,
       r.elapsed_ms,
       r.started_at,
       r.ended_at,
       r.error_message
FROM pipeline_config_run r;

CREATE OR REPLACE VIEW vw_latest_config_pipeline_health AS
SELECT r.config_run_id,
       r.pipeline_code,
       r.status,
       r.loaded_rows,
       r.elapsed_ms,
       r.source_batch_id,
       r.reconciliation_batch_id,
       r.dq_batch_id,
       r.metadata_execution_id,
       r.lineage_run_id,
       CASE
           WHEN r.status = 'SUCCESS'
            AND r.loaded_rows >= 0
            AND r.error_message IS NULL THEN 'HEALTHY'
           WHEN r.status = 'FAILED' THEN 'FAILED'
           ELSE 'WARNING'
       END AS health_status,
       r.started_at,
       r.ended_at
FROM pipeline_config_run r
WHERE r.config_run_id = (SELECT MAX(config_run_id) FROM pipeline_config_run);

CREATE OR REPLACE VIEW vw_config_pipeline_logs AS
SELECT l.log_id,
       l.batch_id,
       b.batch_name,
       l.log_level,
       l.module_name,
       l.message,
       l.created_at
FROM etl_log l
LEFT JOIN etl_batch b ON b.batch_id = l.batch_id
WHERE l.module_name IN ('PKG_PIPELINE_CONFIG','PKG_RECONCILIATION','PKG_DATA_QUALITY','PKG_METADATA_ENGINE','PKG_AUDIT_LINEAGE')
   OR l.message LIKE 'CONFIG_METRIC|%';

PROMPT Pipeline configuration views created.
