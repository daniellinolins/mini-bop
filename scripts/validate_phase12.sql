SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 12
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_RECONCILIATION',
    'VW_RECONCILIATION_METRICS',
    'VW_LATEST_RECONCILIATION_HEALTH',
    'VW_TRADE_RECONCILIATION_DETAIL'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR RECONCILIATION TEST
PROMPT ===========================================

DELETE FROM trade_event;
DELETE FROM trade;

UPDATE stg_trade_raw
   SET processing_status = 'NEW',
       error_count = 0,
       processed_at = NULL,
       batch_id = NULL;

DELETE FROM stg_trade_error;
COMMIT;

PROMPT ===========================================
PROMPT RUNNING OBSERVABILITY PIPELINE AS SOURCE
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

    DBMS_OUTPUT.PUT_LINE('Source batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:           ' || v_loaded_rows);
    DBMS_OUTPUT.PUT_LINE('Elapsed ms:            ' || v_elapsed_ms);
END;
/

PROMPT ===========================================
PROMPT RUNNING RECONCILIATION
PROMPT ===========================================

DECLARE
    v_source_batch_id NUMBER;
    v_recon_batch_id NUMBER;
BEGIN
    SELECT MAX(batch_id)
      INTO v_source_batch_id
      FROM etl_batch
     WHERE batch_name = 'OBSERVABILITY_TRADE_PIPELINE';

    pkg_reconciliation.run_reconciliation(
        p_batch_id       => v_source_batch_id,
        p_recon_batch_id => v_recon_batch_id
    );

    DBMS_OUTPUT.PUT_LINE('Source batch id:        ' || v_source_batch_id);
    DBMS_OUTPUT.PUT_LINE('Reconciliation batch:   ' || v_recon_batch_id);
END;
/

PROMPT ===========================================
PROMPT LATEST RECONCILIATION HEALTH
PROMPT ===========================================

SELECT *
FROM vw_latest_reconciliation_health;

PROMPT ===========================================
PROMPT RECONCILIATION METRICS
PROMPT ===========================================

SELECT batch_id,
       metric_name,
       metric_value,
       created_at
FROM vw_reconciliation_metrics
WHERE batch_id = (
    SELECT MAX(batch_id)
    FROM etl_batch
    WHERE batch_name = 'RECONCILIATION_BATCH'
)
ORDER BY created_at, metric_name;

PROMPT ===========================================
PROMPT TRADE RECONCILIATION DETAIL
PROMPT ===========================================

SELECT batch_id,
       stg_trade_id,
       external_trade_id,
       processing_status,
       trade_id,
       trade_recon_status,
       event_count,
       event_recon_status
FROM vw_trade_reconciliation_detail
WHERE batch_id = (
    SELECT MAX(batch_id)
    FROM etl_batch
    WHERE batch_name = 'OBSERVABILITY_TRADE_PIPELINE'
)
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT LATEST RECONCILIATION LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE batch_id IN (
    SELECT MAX(batch_id)
    FROM etl_batch
    WHERE batch_name = 'RECONCILIATION_BATCH'
)
ORDER BY log_id;
