SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 7
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
    'PKG_TRADE_EVENT',
    'PKG_TRADE_LOAD',
    'PKG_TRADE_LOAD_BULK'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR BULK LOAD TEST
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
PROMPT RUNNING VALIDATION + BULK LOAD
PROMPT ===========================================

DECLARE
    v_batch_id       NUMBER;
    v_loaded_rows    NUMBER;
    v_start_hsecs    NUMBER;
    v_end_hsecs      NUMBER;
    v_elapsed_ms     NUMBER;
BEGIN
    v_batch_id := pkg_log.start_batch(
        p_batch_name    => 'TRADE_BULK_LOAD_TEST',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'sample_phase7_bulk_test.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL;

    v_start_hsecs := DBMS_UTILITY.GET_TIME;

    pkg_trade_validate.validate_batch(v_batch_id);
    v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(v_batch_id, 1000);

    v_end_hsecs := DBMS_UTILITY.GET_TIME;
    v_elapsed_ms := (v_end_hsecs - v_start_hsecs) * 10;

    pkg_log.info(
        v_batch_id,
        'VALIDATE_PHASE7',
        'Bulk load rows=' || v_loaded_rows || ', elapsed_ms=' || v_elapsed_ms
    );

    pkg_log.end_batch(v_batch_id, 'SUCCESS');

    DBMS_OUTPUT.PUT_LINE('Batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:    ' || v_loaded_rows);
    DBMS_OUTPUT.PUT_LINE('Elapsed ms:     ' || v_elapsed_ms);

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
PROMPT TRADE EVENTS
PROMPT ===========================================

SELECT t.trade_id,
       t.external_trade_id,
       e.trade_event_id,
       e.event_type,
       e.event_status,
       e.event_message,
       e.created_at
FROM trade t
JOIN trade_event e
  ON e.trade_id = t.trade_id
ORDER BY t.trade_id, e.trade_event_id;

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
PROMPT LATEST PERFORMANCE LOGS
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
