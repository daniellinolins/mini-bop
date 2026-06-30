SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 6
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
       'PKG_TRADE_LOAD'
 )
 ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR EVENT TEST
PROMPT ===========================================

DELETE FROM trade_event
 WHERE trade_id IN (
       SELECT trade_id
         FROM trade
        WHERE source_system = 'MUREX_SIM'
          AND external_trade_id LIKE 'TRD-%'
 );

DELETE FROM trade
 WHERE source_system = 'MUREX_SIM'
   AND external_trade_id LIKE 'TRD-%';

UPDATE stg_trade_raw
   SET processing_status = 'NEW',
       error_count = 0,
       processed_at = NULL;

DELETE FROM stg_trade_error;

COMMIT;

PROMPT ===========================================
PROMPT RUNNING VALIDATION + LOAD + EVENT GENERATION
PROMPT ===========================================

DECLARE
    v_batch_id NUMBER;
BEGIN
    v_batch_id := pkg_log.start_batch(
        p_batch_name    => 'TRADE_EVENT_TEST',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'sample_phase6_event_test.csv'
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
 WHERE t.source_system = 'MUREX_SIM'
   AND t.external_trade_id LIKE 'TRD-%'
 ORDER BY t.trade_id, e.trade_event_id;

PROMPT ===========================================
PROMPT EVENT COUNTS BY TRADE
PROMPT ===========================================

SELECT t.trade_id,
       t.external_trade_id,
       COUNT(e.trade_event_id) AS event_count
FROM trade t
LEFT JOIN trade_event e
       ON e.trade_id = t.trade_id
GROUP BY t.trade_id,
         t.external_trade_id
ORDER BY t.trade_id;

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
PROMPT LATEST ETL LOGS
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
