SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 2
PROMPT ===========================================

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PKG_COMMON',
    'PKG_ETL_LOG',
    'PKG_TRADE_VALIDATE'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT TESTING BATCH VALIDATION
PROMPT ===========================================

DECLARE
    v_batch_id NUMBER;
BEGIN
    v_batch_id := pkg_etl_log.start_batch(
        p_batch_name    => 'TRADE_VALIDATION_TEST',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'sample_phase2_test.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL
     WHERE batch_id IS NULL
        OR batch_id = 1;

    pkg_trade_validate.validate_batch(v_batch_id);

    pkg_etl_log.end_batch(v_batch_id, 'SUCCESS');

    DBMS_OUTPUT.PUT_LINE('Batch executed: ' || v_batch_id);

    COMMIT;
END;
/

PROMPT ===========================================
PROMPT BATCH RESULT
PROMPT ===========================================

SELECT batch_id,
       batch_name,
       status,
       total_rows,
       valid_rows,
       rejected_rows,
       started_at,
       ended_at
FROM etl_batch
ORDER BY batch_id DESC
FETCH FIRST 5 ROWS ONLY;

PROMPT ===========================================
PROMPT STAGING RESULT
PROMPT ===========================================

SELECT stg_trade_id,
       external_trade_id,
       processing_status,
       error_count
FROM stg_trade_raw
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT VALIDATION ERRORS
PROMPT ===========================================

SELECT e.stg_trade_id,
       e.error_code,
       e.column_name,
       e.error_message
FROM stg_trade_error e
ORDER BY e.stg_trade_id, e.error_code;

PROMPT ===========================================
PROMPT ETL LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
ORDER BY log_id DESC
FETCH FIRST 20 ROWS ONLY;