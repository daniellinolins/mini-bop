SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 11
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_OBSERVABILITY',
    'VW_BATCH_OBSERVABILITY',
    'VW_PIPELINE_METRICS',
    'VW_LATEST_PIPELINE_HEALTH'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR OBSERVABILITY TEST
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
PROMPT RUNNING INSTRUMENTED PIPELINE
PROMPT ===========================================

DECLARE
    v_batch_id NUMBER;
    v_loaded_rows NUMBER;
    v_elapsed_ms NUMBER;
BEGIN
    pkg_observability.run_instrumented_pipeline(
        p_use_bulk    => 'Y',
        p_batch_id    => v_batch_id,
        p_loaded_rows => v_loaded_rows,
        p_elapsed_ms  => v_elapsed_ms
    );

    DBMS_OUTPUT.PUT_LINE('Batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:    ' || v_loaded_rows);
    DBMS_OUTPUT.PUT_LINE('Elapsed ms:     ' || v_elapsed_ms);
END;
/

PROMPT ===========================================
PROMPT LATEST PIPELINE HEALTH
PROMPT ===========================================

SELECT batch_id,
       batch_name,
       status,
       total_rows,
       valid_rows,
       rejected_rows,
       elapsed_ms,
       error_logs,
       metric_logs,
       health_status
FROM vw_latest_pipeline_health;

PROMPT ===========================================
PROMPT PIPELINE METRICS
PROMPT ===========================================

SELECT batch_id,
       module_name,
       metric_name,
       metric_value,
       created_at
FROM vw_pipeline_metrics
WHERE batch_id = (SELECT MAX(batch_id) FROM etl_batch)
ORDER BY created_at, metric_name;

PROMPT ===========================================
PROMPT SESSION INSTRUMENTATION CHECK
PROMPT ===========================================

SELECT SYS_CONTEXT('USERENV', 'MODULE') AS current_module,
       SYS_CONTEXT('USERENV', 'ACTION') AS current_action
FROM dual;

PROMPT ===========================================
PROMPT STAGING STATUS SUMMARY
PROMPT ===========================================

SELECT processing_status,
       COUNT(*) AS total_rows
FROM stg_trade_raw
GROUP BY processing_status
ORDER BY processing_status;

PROMPT ===========================================
PROMPT LATEST OBSERVABILITY LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE batch_id = (SELECT MAX(batch_id) FROM etl_batch)
ORDER BY log_id;
