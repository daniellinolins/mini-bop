SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 14
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_DATA_QUALITY',
    'VW_DQ_RULE_RESULTS',
    'VW_DQ_BATCH_SUMMARY',
    'VW_LATEST_DQ_HEALTH',
    'VW_DQ_FAILED_RULES'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR DATA QUALITY TEST
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
PROMPT RUNNING BASE PIPELINE AS DATA QUALITY SOURCE
PROMPT ===========================================

DECLARE
    v_source_batch_id NUMBER;
    v_loaded_rows     NUMBER;
BEGIN
    v_source_batch_id := pkg_log.start_batch(
        p_batch_name    => 'DATA_QUALITY_SOURCE_PIPELINE',
        p_source_system => 'MUREX_SIM',
        p_file_name     => 'phase14_dq_source.csv'
    );

    UPDATE stg_trade_raw
       SET batch_id = v_source_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL;

    pkg_log.info(v_source_batch_id, 'VALIDATE_PHASE14', 'Source pipeline attached rows=' || SQL%ROWCOUNT);
    pkg_trade_validate.validate_batch(v_source_batch_id);
    v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(v_source_batch_id);
    pkg_log.info(v_source_batch_id, 'VALIDATE_PHASE14', 'Source pipeline loaded_rows=' || v_loaded_rows);
    pkg_log.end_batch(v_source_batch_id, 'SUCCESS');
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Source batch executed: ' || v_source_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:           ' || v_loaded_rows);
END;
/

PROMPT ===========================================
PROMPT RUNNING DATA QUALITY CHECK
PROMPT ===========================================

DECLARE
    v_source_batch_id NUMBER;
    v_dq_batch_id     NUMBER;
BEGIN
    SELECT MAX(batch_id)
      INTO v_source_batch_id
      FROM etl_batch
     WHERE batch_name = 'DATA_QUALITY_SOURCE_PIPELINE';

    v_dq_batch_id := pkg_data_quality.run_trade_dq(v_source_batch_id);

    DBMS_OUTPUT.PUT_LINE('Source batch id:  ' || v_source_batch_id);
    DBMS_OUTPUT.PUT_LINE('DQ batch executed: ' || v_dq_batch_id);
END;
/

PROMPT ===========================================
PROMPT DATA QUALITY HEALTH
PROMPT ===========================================

SELECT *
FROM vw_latest_dq_health;

PROMPT ===========================================
PROMPT DATA QUALITY RULE RESULTS
PROMPT ===========================================

SELECT rule_code,
       severity,
       rule_type,
       total_rows,
       failed_rows,
       passed_rows,
       quality_score,
       result_status
FROM vw_dq_rule_results
WHERE dq_batch_id = (SELECT MAX(batch_id) FROM etl_batch WHERE batch_name = 'DATA_QUALITY_CHECK')
ORDER BY severity DESC, rule_code;

PROMPT ===========================================
PROMPT FAILED OR WARNING RULES
PROMPT ===========================================

SELECT rule_code,
       severity,
       failed_rows,
       quality_score,
       result_status
FROM vw_dq_failed_rules
WHERE dq_batch_id = (SELECT MAX(batch_id) FROM etl_batch WHERE batch_name = 'DATA_QUALITY_CHECK')
ORDER BY severity DESC, rule_code;

PROMPT ===========================================
PROMPT DATA QUALITY LOGS
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
     WHERE batch_name = 'DATA_QUALITY_CHECK'
)
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

PROMPT Phase 14 validation completed.
