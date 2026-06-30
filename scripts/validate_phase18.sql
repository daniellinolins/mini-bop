SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200
SET DEFINE OFF

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 18
PROMPT ===========================================

COLUMN object_name FORMAT A40
COLUMN object_type FORMAT A25
COLUMN status FORMAT A10

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_HADOOP_EXPORT',
    'VW_EXPORT_FILES',
    'VW_EXPORT_JOB_SUMMARY',
    'VW_EXPORT_MANIFEST',
    'VW_LATEST_EXPORT_HEALTH'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT RESETTING SAMPLE DATA FOR EXPORT TEST
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
PROMPT RUNNING CONFIGURED PIPELINE AS EXPORT SOURCE
PROMPT ===========================================

VARIABLE v_config_run_id NUMBER
VARIABLE v_source_batch_id NUMBER
VARIABLE v_export_job_id NUMBER

DECLARE
    v_config_run_id NUMBER;
    v_source_batch_id NUMBER;
BEGIN
    v_config_run_id := pkg_pipeline_config.run_configured_pipeline('DAILY_TRADE_PIPELINE');

    SELECT source_batch_id
      INTO v_source_batch_id
      FROM vw_latest_config_pipeline_health
     WHERE config_run_id = v_config_run_id;

    :v_config_run_id := v_config_run_id;
    :v_source_batch_id := v_source_batch_id;

    DBMS_OUTPUT.PUT_LINE('Config run executed: ' || v_config_run_id);
    DBMS_OUTPUT.PUT_LINE('Source batch id:      ' || v_source_batch_id);
END;
/

PROMPT ===========================================
PROMPT SOURCE BATCH FOR EXPORT
PROMPT ===========================================

SELECT :v_source_batch_id AS source_batch_id
FROM dual;

PROMPT ===========================================
PROMPT RUNNING ORACLE CSV EXPORT
PROMPT ===========================================

DECLARE
    v_export_job_id NUMBER;
BEGIN
    v_export_job_id := pkg_hadoop_export.export_trades_csv(
        p_source_batch_id  => :v_source_batch_id,
        p_hdfs_target_path => '/data/mini_bop/trade'
    );

    pkg_hadoop_export.validate_export(v_export_job_id);

    :v_export_job_id := v_export_job_id;

    DBMS_OUTPUT.PUT_LINE('Export job executed: ' || v_export_job_id);
END;
/

PROMPT ===========================================
PROMPT LATEST EXPORT HEALTH
PROMPT ===========================================

SELECT *
FROM vw_latest_export_health;

PROMPT ===========================================
PROMPT EXPORT JOB SUMMARY
PROMPT ===========================================

COLUMN export_name FORMAT A35
COLUMN target_system FORMAT A20
COLUMN export_format FORMAT A15
COLUMN export_status FORMAT A20
COLUMN output_directory FORMAT A25
COLUMN hdfs_target_path FORMAT A40

SELECT export_job_id,
       export_name,
       source_batch_id,
       target_system,
       export_format,
       export_status,
       output_directory,
       hdfs_target_path,
       total_rows,
       exported_rows,
       rejected_rows,
       elapsed_ms,
       started_at,
       ended_at
FROM vw_export_job_summary
WHERE export_job_id = :v_export_job_id;

PROMPT ===========================================
PROMPT EXPORT FILES
PROMPT ===========================================

COLUMN file_role FORMAT A20
COLUMN file_name FORMAT A45
COLUMN file_path FORMAT A70
COLUMN hdfs_path FORMAT A60
COLUMN file_status FORMAT A20

SELECT export_job_id,
       export_status,
       export_file_id,
       file_role,
       file_name,
       file_path,
       hdfs_path,
       row_count,
       file_status,
       created_at
FROM vw_export_files
WHERE export_job_id = :v_export_job_id
ORDER BY export_file_id;

PROMPT ===========================================
PROMPT EXPORT MANIFEST
PROMPT ===========================================

COLUMN manifest_key FORMAT A35
COLUMN manifest_value FORMAT A90

SELECT export_job_id,
       manifest_key,
       manifest_value,
       created_at
FROM vw_export_manifest
WHERE export_job_id = :v_export_job_id
ORDER BY manifest_key;

PROMPT ===========================================
PROMPT EXPORT LOGS
PROMPT ===========================================

COLUMN module_name FORMAT A35
COLUMN message FORMAT A120

SELECT log_id,
       batch_id,
       log_level,
       module_name,
       message,
       created_at
FROM etl_log
WHERE module_name = 'PKG_HADOOP_EXPORT'
   OR message LIKE 'EXPORT_%'
ORDER BY log_id DESC
FETCH FIRST 30 ROWS ONLY;

PROMPT ===========================================
PROMPT LOCAL EXPORT DIRECTORY CHECK
PROMPT ===========================================

PROMPT If export succeeded, check files in:
PROMPT F:\SSD_DEV\windows\projects\mini-bop\data\export
PROMPT
PROMPT From Git Bash / WSL, next commands are:
PROMPT bash hadoop/hdfs/180_create_hdfs_dirs.sh
PROMPT bash hadoop/hdfs/181_upload_exports_to_hdfs.sh /mnt/f/SSD_DEV/windows/projects/mini-bop/data/export /data/mini_bop/trade

PROMPT Phase 18 validation completed.
