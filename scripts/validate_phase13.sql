SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 13
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_RECOVERY',
    'VW_RECOVERY_CANDIDATES',
    'VW_RECOVERY_BATCH_SUMMARY',
    'VW_LATEST_RECOVERY_ACTIVITY'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR RECOVERY TEST
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
PROMPT RUNNING BASE PIPELINE TO CREATE REJECTED ROWS
PROMPT ===========================================

VARIABLE v_source_batch_id NUMBER

DECLARE
    v_batch_id    NUMBER;
    v_loaded_rows NUMBER;
BEGIN
    v_batch_id := pkg_log.start_batch(
        p_batch_name    => 'RECOVERY_BASE_PIPELINE',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'recovery_base_test.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL;

    pkg_log.info(v_batch_id, 'VALIDATE_PHASE13', 'Base pipeline attached rows=' || SQL%ROWCOUNT);

    pkg_trade_validate.validate_batch(v_batch_id);

    v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(v_batch_id);

    pkg_log.info(v_batch_id, 'VALIDATE_PHASE13', 'Base pipeline loaded_rows=' || v_loaded_rows);

    pkg_log.end_batch(v_batch_id, 'SUCCESS');

    :v_source_batch_id := v_batch_id;

    DBMS_OUTPUT.PUT_LINE('Source batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:           ' || v_loaded_rows);

    COMMIT;
END;
/

PROMPT ===========================================
PROMPT STAGING STATUS AFTER BASE PIPELINE
PROMPT ===========================================

SELECT processing_status,
       COUNT(*) AS total_rows
FROM stg_trade_raw
GROUP BY processing_status
ORDER BY processing_status;

PROMPT ===========================================
PROMPT RECOVERY CANDIDATES BEFORE FIX
PROMPT ===========================================

SELECT batch_id,
       stg_trade_id,
       external_trade_id,
       processing_status,
       error_count,
       recovery_status
FROM vw_recovery_candidates
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT SIMULATING SOURCE DATA FIXES
PROMPT ===========================================

UPDATE stg_trade_raw
   SET counterparty_code = (
           SELECT MIN(counterparty_code)
           FROM counterparty
       )
 WHERE external_trade_id = 'TRD-000004';

UPDATE stg_trade_raw
   SET quantity_txt = '1000'
 WHERE external_trade_id = 'TRD-000005';

COMMIT;

PROMPT ===========================================
PROMPT RESTARTING ONLY REJECTED TRADES
PROMPT ===========================================

VARIABLE v_recovery_batch_id NUMBER

DECLARE
    v_recovery_batch_id NUMBER;
BEGIN
    v_recovery_batch_id := pkg_recovery.restart_rejected_trades;
    :v_recovery_batch_id := v_recovery_batch_id;
    DBMS_OUTPUT.PUT_LINE('Recovery batch executed: ' || v_recovery_batch_id);
    COMMIT;
END;
/

PROMPT ===========================================
PROMPT STAGING STATUS SUMMARY AFTER RECOVERY
PROMPT ===========================================

SELECT processing_status,
       COUNT(*) AS total_rows
FROM stg_trade_raw
GROUP BY processing_status
ORDER BY processing_status;

PROMPT ===========================================
PROMPT LOADED TRADES AFTER RECOVERY
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
PROMPT RECOVERY CANDIDATES AFTER RECOVERY
PROMPT ===========================================

SELECT batch_id,
       stg_trade_id,
       external_trade_id,
       processing_status,
       error_count,
       recovery_status
FROM vw_recovery_candidates
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT RECOVERY BATCH SUMMARY
PROMPT ===========================================

SELECT *
FROM vw_recovery_batch_summary
WHERE batch_id IN (:v_source_batch_id, :v_recovery_batch_id)
ORDER BY batch_id DESC;

PROMPT ===========================================
PROMPT LATEST RECOVERY ACTIVITY
PROMPT ===========================================

SELECT log_id,
       batch_id,
       batch_name,
       log_level,
       module_name,
       message,
       created_at
FROM vw_latest_recovery_activity
WHERE batch_id IN (:v_source_batch_id, :v_recovery_batch_id)
ORDER BY log_id;

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

PROMPT Phase 13 validation completed.
