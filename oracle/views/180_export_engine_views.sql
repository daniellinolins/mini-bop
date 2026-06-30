PROMPT Creating export engine views...

CREATE OR REPLACE VIEW vw_export_job_summary AS
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
       ROUND(EXTRACT(DAY FROM (ended_at - started_at)) * 86400000
             + EXTRACT(HOUR FROM (ended_at - started_at)) * 3600000
             + EXTRACT(MINUTE FROM (ended_at - started_at)) * 60000
             + EXTRACT(SECOND FROM (ended_at - started_at)) * 1000) AS elapsed_ms,
       started_at,
       ended_at,
       created_by
  FROM export_job;

CREATE OR REPLACE VIEW vw_export_files AS
SELECT j.export_job_id,
       j.export_name,
       j.export_status,
       f.export_file_id,
       f.file_role,
       f.file_name,
       f.file_path,
       f.hdfs_path,
       f.row_count,
       f.file_status,
       f.created_at
  FROM export_job j
  JOIN export_file f
    ON f.export_job_id = j.export_job_id;

CREATE OR REPLACE VIEW vw_export_manifest AS
SELECT j.export_job_id,
       j.export_name,
       j.source_batch_id,
       m.manifest_key,
       m.manifest_value,
       m.created_at
  FROM export_job j
  JOIN export_manifest m
    ON m.export_job_id = j.export_job_id;

CREATE OR REPLACE VIEW vw_latest_export_health AS
WITH latest_export AS (
    SELECT MAX(export_job_id) AS export_job_id
      FROM export_job
)
SELECT j.export_job_id,
       j.export_name,
       j.source_batch_id,
       j.export_status,
       j.total_rows,
       j.exported_rows,
       j.rejected_rows,
       COUNT(f.export_file_id) AS file_count,
       SUM(CASE WHEN f.file_role = 'DATA' THEN f.row_count ELSE 0 END) AS data_file_rows,
       CASE
           WHEN j.export_status = 'SUCCESS'
            AND j.total_rows = j.exported_rows
            AND j.exported_rows = SUM(CASE WHEN f.file_role = 'DATA' THEN f.row_count ELSE 0 END)
           THEN 'READY_FOR_HDFS'
           WHEN j.export_status = 'FAILED'
           THEN 'FAILED'
           ELSE 'CHECK_REQUIRED'
       END AS export_health,
       j.hdfs_target_path,
       j.started_at,
       j.ended_at
  FROM latest_export le
  JOIN export_job j
    ON j.export_job_id = le.export_job_id
  LEFT JOIN export_file f
    ON f.export_job_id = j.export_job_id
 GROUP BY j.export_job_id,
          j.export_name,
          j.source_batch_id,
          j.export_status,
          j.total_rows,
          j.exported_rows,
          j.rejected_rows,
          j.hdfs_target_path,
          j.started_at,
          j.ended_at;

PROMPT Export engine views created.
