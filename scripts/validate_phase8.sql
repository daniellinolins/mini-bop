SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 8
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
    'PKG_BATCH_SCHEDULER'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR SCHEDULER TEST
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
PROMPT CREATING DAILY SCHEDULER JOB
PROMPT ===========================================

BEGIN
    pkg_batch_scheduler.drop_daily_trade_job;
    pkg_batch_scheduler.create_daily_trade_job('02:00');
    DBMS_OUTPUT.PUT_LINE('Scheduler job created: ' || pkg_batch_scheduler.c_daily_trade_job);
END;
/

PROMPT ===========================================
PROMPT SCHEDULER JOB METADATA
PROMPT ===========================================

SELECT job_name,
       enabled,
       state,
       repeat_interval,
       job_type
FROM user_scheduler_jobs
WHERE job_name = 'MINI_BOP_DAILY_TRADE_PIPELINE';

PROMPT ===========================================
PROMPT RUNNING SCHEDULER JOB NOW
PROMPT ===========================================

BEGIN
    pkg_batch_scheduler.run_daily_trade_job_now(p_use_current_session => TRUE);
    DBMS_OUTPUT.PUT_LINE('Scheduler job executed in current session.');
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
PROMPT SCHEDULER LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE module_name IN ('PKG_BATCH_SCHEDULER', 'PKG_TRADE_LOAD_BULK', 'PKG_TRADE_VALIDATE', 'PKG_LOG')
ORDER BY log_id DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT ===========================================
PROMPT SCHEDULER RUN DETAILS
PROMPT ===========================================

SELECT job_name,
       status,
       actual_start_date,
       run_duration,
       errors
FROM user_scheduler_job_run_details
WHERE job_name = 'MINI_BOP_DAILY_TRADE_PIPELINE'
ORDER BY log_date DESC
FETCH FIRST 5 ROWS ONLY;
