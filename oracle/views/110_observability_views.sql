PROMPT Creating observability views...

CREATE OR REPLACE VIEW vw_batch_observability AS
SELECT b.batch_id,
       b.batch_name,
       b.source_system,
       b.file_name,
       b.status,
       b.total_rows,
       b.valid_rows,
       b.rejected_rows,
       b.started_at,
       b.ended_at,
       ROUND(
           EXTRACT(DAY FROM (b.ended_at - b.started_at)) * 86400000 +
           EXTRACT(HOUR FROM (b.ended_at - b.started_at)) * 3600000 +
           EXTRACT(MINUTE FROM (b.ended_at - b.started_at)) * 60000 +
           EXTRACT(SECOND FROM (b.ended_at - b.started_at)) * 1000
       ) AS elapsed_ms,
       (SELECT COUNT(*) FROM etl_log l WHERE l.batch_id = b.batch_id AND l.log_level = 'ERROR') AS error_logs,
       (SELECT COUNT(*) FROM etl_log l WHERE l.batch_id = b.batch_id AND l.message LIKE 'METRIC|%') AS metric_logs
  FROM etl_batch b;
/

CREATE OR REPLACE VIEW vw_pipeline_metrics AS
SELECT l.batch_id,
       l.module_name,
       SUBSTR(l.message, 8, INSTR(l.message, '=') - 8) AS metric_name,
       TO_NUMBER(SUBSTR(l.message, INSTR(l.message, '=') + 1)) AS metric_value,
       l.created_at
  FROM etl_log l
 WHERE l.message LIKE 'METRIC|%';
/

CREATE OR REPLACE VIEW vw_latest_pipeline_health AS
SELECT b.batch_id,
       b.batch_name,
       b.status,
       b.total_rows,
       b.valid_rows,
       b.rejected_rows,
       b.elapsed_ms,
       b.error_logs,
       b.metric_logs,
       CASE
           WHEN b.status = 'SUCCESS' AND b.error_logs = 0 THEN 'HEALTHY'
           WHEN b.status = 'SUCCESS' AND b.error_logs > 0 THEN 'SUCCESS_WITH_ERRORS'
           ELSE 'UNHEALTHY'
       END AS health_status
  FROM vw_batch_observability b
 WHERE b.batch_id = (SELECT MAX(batch_id) FROM etl_batch);
/

PROMPT Observability views created.
