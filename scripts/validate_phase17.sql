SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 17
PROMPT ===========================================

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PKG_PIPELINE_CONFIG',
    'VW_PIPELINE_CONFIG_CATALOG',
    'VW_PIPELINE_CONFIG_RUNS',
    'VW_LATEST_CONFIG_PIPELINE_HEALTH',
    'VW_CONFIG_PIPELINE_LOGS'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR CONFIG PIPELINE TEST
PROMPT ===========================================

DELETE FROM trade_event;
DELETE FROM trade;

UPDATE stg_trade_raw
   SET batch_id = NULL,
       processing_status = 'NEW',
       error_count = 0,
       processed_at = NULL;

DELETE FROM stg_trade_error;
COMMIT;

PROMPT ===========================================
PROMPT PIPELINE CONFIG CATALOG
PROMPT ===========================================

SELECT pipeline_code,
       is_active,
       use_bulk,
       use_parallel,
       parallel_level,
       bulk_limit,
       run_reconciliation,
       run_data_quality,
       run_metadata_rules,
       run_lineage,
       metadata_rule_group
FROM vw_pipeline_config_catalog
ORDER BY pipeline_code;

PROMPT ===========================================
PROMPT RUNNING CONFIGURED PIPELINE
PROMPT ===========================================

DECLARE
    v_config_run_id NUMBER;
BEGIN
    v_config_run_id := pkg_pipeline_config.run_configured_pipeline('DAILY_TRADE_PIPELINE');
    DBMS_OUTPUT.PUT_LINE('Config run executed: ' || v_config_run_id);
END;
/

PROMPT ===========================================
PROMPT LATEST CONFIG PIPELINE HEALTH
PROMPT ===========================================

SELECT *
FROM vw_latest_config_pipeline_health;

PROMPT ===========================================
PROMPT CONFIG PIPELINE RUNS
PROMPT ===========================================

SELECT config_run_id,
       pipeline_code,
       status,
       source_batch_id,
       reconciliation_batch_id,
       dq_batch_id,
       metadata_execution_id,
       lineage_run_id,
       loaded_rows,
       elapsed_ms,
       started_at,
       ended_at
FROM vw_pipeline_config_runs
ORDER BY config_run_id DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT ===========================================
PROMPT STAGING STATUS SUMMARY
PROMPT ===========================================

SELECT processing_status, COUNT(*) AS total_rows
FROM stg_trade_raw
GROUP BY processing_status
ORDER BY processing_status;

PROMPT ===========================================
PROMPT LOADED TRADES
PROMPT ===========================================

SELECT trade_id,
       external_trade_id,
       source_system,
       trade_date,
       buy_sell,
       quantity,
       trade_price,
       trade_currency,
       notional_amount,
       amount_eur,
       trade_status
FROM trade
ORDER BY trade_id;

PROMPT ===========================================
PROMPT LATEST CONFIG PIPELINE LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       batch_name,
       log_level,
       module_name,
       message,
       created_at
FROM vw_config_pipeline_logs
ORDER BY log_id DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT ===========================================
PROMPT DOWNSTREAM VALIDATION SUMMARY
PROMPT ===========================================

SELECT 'RECONCILIATION' AS component,
       reconciliation_status AS status,
       missing_trade_rows AS issue_count
FROM vw_latest_reconciliation_health
UNION ALL
SELECT 'DATA_QUALITY' AS component,
       dq_status AS status,
       failed_rules AS issue_count
FROM vw_latest_dq_health
UNION ALL
SELECT 'METADATA_ENGINE' AS component,
       health_status AS status,
       failed_rules AS issue_count
FROM vw_latest_md_engine_health
UNION ALL
SELECT 'LINEAGE' AS component,
       lineage_health AS status,
       incomplete_rows AS issue_count
FROM vw_latest_lineage_health;

PROMPT Phase 17 validation completed.
