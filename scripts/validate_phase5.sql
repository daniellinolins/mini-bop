SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 5
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_COMMON',
    'PKG_LOG',
    'PKG_TRADE_VALIDATE',
    'PKG_TRADE_LOOKUP',
    'PKG_TRADE_TYPES',
    'PKG_TRADE_TRANSFORM',
    'PKG_TRADE_LOAD'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR LOAD TEST
PROMPT ===========================================

DELETE FROM trade_event
 WHERE trade_id IN (
    SELECT t.trade_id
      FROM trade t
     WHERE EXISTS (
        SELECT 1
          FROM stg_trade_raw s
         WHERE s.external_trade_id = t.external_trade_id
           AND s.source_system = t.source_system
     )
 );

DELETE FROM trade
 WHERE EXISTS (
    SELECT 1
      FROM stg_trade_raw s
     WHERE s.external_trade_id = trade.external_trade_id
       AND s.source_system = trade.source_system
 );

UPDATE stg_trade_raw
   SET batch_id = NULL,
       processing_status = 'NEW',
       error_count = 0,
       processed_at = NULL;

DELETE FROM stg_trade_error;

COMMIT;

PROMPT ===========================================
PROMPT RUNNING VALIDATION + LOAD
PROMPT ===========================================

DECLARE
    v_batch_id NUMBER;
BEGIN
    v_batch_id := pkg_log.start_batch(
        p_batch_name    => 'TRADE_LOAD_TEST',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'sample_phase5_test.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL;

    pkg_trade_validate.validate_batch(v_batch_id);
    pkg_trade_load.load_batch(v_batch_id);
    pkg_log.end_batch(v_batch_id, 'SUCCESS');

    DBMS_OUTPUT.PUT_LINE('Batch executed: ' || v_batch_id);

    COMMIT;
END;
/

PROMPT ===========================================
PROMPT STAGING STATUS SUMMARY
PROMPT ===========================================

SELECT processing_status,
       COUNT(*) AS total_rows
FROM stg_trade_raw
GROUP BY processing_status
ORDER BY processing_status;

PROMPT ===========================================
PROMPT LOADED TRADES
PROMPT ===========================================

SELECT trade_id,
       external_trade_id,
       source_system,
       TO_CHAR(trade_date, 'YYYY-MM-DD') AS trade_date,
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
PROMPT LATEST BATCH RESULT
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
PROMPT VALIDATION ERRORS
PROMPT ===========================================

SELECT stg_trade_id,
       error_code,
       column_name,
       error_message
FROM stg_trade_error
ORDER BY stg_trade_id, error_code;

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
FETCH FIRST 30 ROWS ONLY;
