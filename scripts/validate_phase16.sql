SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 16
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_AUDIT_LINEAGE',
    'VW_TRADE_LINEAGE_DETAIL',
    'VW_LINEAGE_TIMELINE',
    'VW_LATEST_LINEAGE_HEALTH',
    'VW_TRADE_FULL_JOURNEY'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR LINEAGE TEST
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
PROMPT RUNNING SOURCE PIPELINE FOR LINEAGE
PROMPT ===========================================

DECLARE
    v_source_batch_id NUMBER;
    v_loaded_rows     NUMBER;
    v_lineage_run_id  NUMBER;
BEGIN
    v_source_batch_id := pkg_log.start_batch(
        p_batch_name    => 'LINEAGE_SOURCE_PIPELINE',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'phase16_lineage_source.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_source_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL;

    pkg_trade_validate.validate_batch(v_source_batch_id);
    v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(v_source_batch_id, 1000);
    pkg_log.end_batch(v_source_batch_id, 'SUCCESS');

    v_lineage_run_id := pkg_audit_lineage.build_lineage_for_batch(v_source_batch_id);

    DBMS_OUTPUT.PUT_LINE('Source batch executed: ' || v_source_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:           ' || v_loaded_rows);
    DBMS_OUTPUT.PUT_LINE('Lineage run executed:  ' || v_lineage_run_id);
END;
/

PROMPT ===========================================
PROMPT LATEST LINEAGE HEALTH
PROMPT ===========================================

SELECT lineage_run_id,
       source_batch_id,
       status,
       total_rows,
       complete_rows,
       rejected_source_rows,
       incomplete_rows,
       lineage_health,
       started_at,
       ended_at
FROM vw_latest_lineage_health;

PROMPT ===========================================
PROMPT TRADE LINEAGE DETAIL
PROMPT ===========================================

SELECT lineage_run_id,
       source_batch_id,
       stg_trade_id,
       external_trade_id,
       staging_status,
       trade_id,
       trade_status,
       event_count,
       lineage_status
FROM vw_trade_lineage_detail
WHERE lineage_run_id = pkg_audit_lineage.latest_lineage_run_id
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT LINEAGE TIMELINE
PROMPT ===========================================

SELECT stg_trade_id,
       external_trade_id,
       step_name,
       step_status,
       step_message
FROM vw_lineage_timeline
WHERE lineage_run_id = pkg_audit_lineage.latest_lineage_run_id
ORDER BY stg_trade_id,
         CASE step_name
            WHEN 'RAW_CAPTURE' THEN 1
            WHEN 'VALIDATION' THEN 2
            WHEN 'CORE_LOAD' THEN 3
            WHEN 'EVENT_GENERATION' THEN 4
            ELSE 99
         END;

PROMPT ===========================================
PROMPT FULL TRADE JOURNEY
PROMPT ===========================================

SELECT source_batch_id,
       stg_trade_id,
       external_trade_id,
       processing_status,
       trade_id,
       trade_status,
       event_count,
       notional_amount,
       amount_eur
FROM vw_trade_full_journey
ORDER BY stg_trade_id;

PROMPT ===========================================
PROMPT LATEST LINEAGE LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE module_name = 'PKG_AUDIT_LINEAGE'
ORDER BY log_id DESC
FETCH FIRST 20 ROWS ONLY;

PROMPT Phase 16 validation completed.
