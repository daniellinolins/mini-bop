SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 15
PROMPT ===========================================

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN (
    'PKG_METADATA_ENGINE',
    'VW_MD_RULE_CATALOG',
    'VW_MD_EXECUTION_SUMMARY',
    'VW_MD_RULE_RESULTS',
    'VW_LATEST_MD_ENGINE_HEALTH',
    'VW_MD_FAILED_RULES'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR METADATA ENGINE TEST
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
PROMPT RUNNING SOURCE PIPELINE
PROMPT ===========================================

DECLARE
    v_batch_id NUMBER;
    v_loaded   NUMBER;
BEGIN
    v_batch_id := pkg_log.start_batch('METADATA_ENGINE_SOURCE_PIPELINE', 'MUREX_SIM', 'metadata_source.csv');

    UPDATE stg_trade_raw
       SET batch_id = v_batch_id,
           processing_status = 'NEW',
           error_count = 0,
           processed_at = NULL
     WHERE batch_id IS NULL;

    COMMIT;

    pkg_trade_validate.validate_batch(v_batch_id);
    v_loaded := pkg_trade_load_bulk.load_validated_bulk(v_batch_id);
    pkg_log.end_batch(v_batch_id, 'SUCCESS');
    COMMIT;

    DBMS_OUTPUT.PUT_LINE('Source batch executed: ' || v_batch_id);
    DBMS_OUTPUT.PUT_LINE('Loaded rows:           ' || v_loaded);
END;
/

PROMPT ===========================================
PROMPT METADATA RULE CATALOG
PROMPT ===========================================

SELECT rule_group_code,
       rule_code,
       target_table,
       severity,
       rule_type,
       active_flag,
       execution_order
FROM vw_md_rule_catalog
ORDER BY execution_order;

PROMPT ===========================================
PROMPT RUNNING METADATA RULE GROUP
PROMPT ===========================================

DECLARE
    v_source_batch_id NUMBER;
    v_execution_id    NUMBER;
BEGIN
    SELECT MAX(batch_id)
      INTO v_source_batch_id
      FROM etl_batch
     WHERE batch_name = 'METADATA_ENGINE_SOURCE_PIPELINE';

    v_execution_id := pkg_metadata_engine.run_rule_group(
        p_rule_group_code => 'TRADE_STAGING_DQ',
        p_source_batch_id => v_source_batch_id
    );

    DBMS_OUTPUT.PUT_LINE('Source batch id:       ' || v_source_batch_id);
    DBMS_OUTPUT.PUT_LINE('Metadata execution id: ' || v_execution_id);
END;
/

PROMPT ===========================================
PROMPT LATEST METADATA ENGINE HEALTH
PROMPT ===========================================

SELECT execution_id,
       batch_id,
       source_batch_id,
       rule_group_code,
       status,
       total_rules,
       passed_rules,
       warning_rules,
       failed_rules,
       avg_score,
       health_status
FROM vw_latest_md_engine_health;

PROMPT ===========================================
PROMPT METADATA RULE RESULTS
PROMPT ===========================================

SELECT rule_code,
       severity,
       rule_type,
       total_rows,
       failed_rows,
       passed_rows,
       quality_score,
       result_status
FROM vw_md_rule_results
WHERE execution_id = (SELECT MAX(execution_id) FROM md_rule_execution)
ORDER BY rule_code;

PROMPT ===========================================
PROMPT FAILED OR WARNING METADATA RULES
PROMPT ===========================================

SELECT rule_code,
       severity,
       result_status,
       failed_rows,
       quality_score,
       error_message
FROM vw_md_failed_rules
WHERE execution_id = (SELECT MAX(execution_id) FROM md_rule_execution)
ORDER BY severity, rule_code;

PROMPT ===========================================
PROMPT LATEST METADATA ENGINE LOGS
PROMPT ===========================================

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE module_name = 'PKG_METADATA_ENGINE'
   OR batch_id = (SELECT MAX(batch_id) FROM md_rule_execution)
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

PROMPT Phase 15 validation completed.
