SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 9
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
    'PKG_TRADE_LOAD_BULK',
    'PKG_BATCH_SCHEDULER',
    'PKG_TRADE_PARALLEL'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR PARALLEL TEST
PROMPT ===========================================

DELETE FROM trade_event;
DELETE FROM trade;

UPDATE stg_trade_raw
   SET batch_id = NULL,
       processing_status = 'NEW',
       error_count = 0,
       processed_at = NULL
 WHERE stg_trade_id BETWEEN 1 AND 5;

DELETE FROM stg_trade_error;
COMMIT;

PROMPT ===========================================
PROMPT RUNNING PARALLEL PIPELINE
PROMPT ===========================================

DECLARE
    v_batch_id    NUMBER;
    v_loaded_rows NUMBER;
    v_elapsed_ms  NUMBER;
BEGIN
    UPDATE stg_trade_raw
       SET batch_id = NULL,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL
     WHERE stg_trade_id BETWEEN 1 AND 5;

    COMMIT;

    pkg_trade_parallel.run_parallel_pipeline(
        p_parallel_level => 4,
        p_batch_id       => v_batch_id,
        p_loaded_rows    => v_loaded_rows,
        p_elapsed_ms     => v_elapsed_ms
    );

    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:    ' || v_loaded_rows);
    DBMS_OUTPUT.PUT_LINE('Elapsed ms:     ' || v_elapsed_ms);
END;
/

PROMPT ===========================================
PROMPT STAGING STATUS SUMMARY
PROMPT ===========================================

SELECT processing_status,
       COUNT(*) AS total_rows
FROM stg_trade_raw
WHERE stg_trade_id BETWEEN 1 AND 5
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
PROMPT PARALLEL CHUNK LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE module_name = 'PKG_TRADE_PARALLEL'
ORDER BY log_id DESC
FETCH FIRST 30 ROWS ONLY;

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
