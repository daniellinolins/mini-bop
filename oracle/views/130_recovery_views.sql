PROMPT Creating recovery views...

CREATE OR REPLACE VIEW vw_recovery_candidates AS
SELECT s.batch_id,
       s.stg_trade_id,
       s.external_trade_id,
       s.source_system,
       s.processing_status,
       s.error_count,
       s.processed_at,
       CASE
           WHEN s.processing_status = 'REJECTED' THEN 'RESTART_CANDIDATE'
           WHEN s.processing_status = 'NEW' THEN 'PENDING'
           WHEN s.processing_status = 'VALIDATED' THEN 'READY_TO_LOAD'
           WHEN s.processing_status = 'PROCESSED' THEN 'ALREADY_PROCESSED'
           ELSE 'UNKNOWN'
       END AS recovery_status
FROM stg_trade_raw s;
/

CREATE OR REPLACE VIEW vw_recovery_batch_summary AS
SELECT b.batch_id,
       b.batch_name,
       b.status,
       b.started_at,
       b.ended_at,
       b.total_rows,
       b.valid_rows,
       b.rejected_rows,
       SUM(CASE WHEN s.processing_status = 'NEW' THEN 1 ELSE 0 END) AS new_rows,
       SUM(CASE WHEN s.processing_status = 'VALIDATED' THEN 1 ELSE 0 END) AS validated_rows,
       SUM(CASE WHEN s.processing_status = 'PROCESSED' THEN 1 ELSE 0 END) AS processed_rows,
       SUM(CASE WHEN s.processing_status = 'REJECTED' THEN 1 ELSE 0 END) AS rejected_staging_rows
FROM etl_batch b
LEFT JOIN stg_trade_raw s
       ON s.batch_id = b.batch_id
GROUP BY b.batch_id,
         b.batch_name,
         b.status,
         b.started_at,
         b.ended_at,
         b.total_rows,
         b.valid_rows,
         b.rejected_rows;
/

CREATE OR REPLACE VIEW vw_latest_recovery_activity AS
SELECT l.log_id,
       l.batch_id,
       b.batch_name,
       l.log_level,
       l.module_name,
       l.message,
       l.created_at
FROM etl_log l
LEFT JOIN etl_batch b
       ON b.batch_id = l.batch_id
WHERE l.module_name = 'PKG_RECOVERY'
   OR b.batch_name LIKE 'RECOVERY_%';
/

PROMPT Recovery views created.
