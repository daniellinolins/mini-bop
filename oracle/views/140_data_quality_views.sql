PROMPT Creating data quality views...

CREATE OR REPLACE VIEW vw_dq_rule_results AS
SELECT r.dq_batch_id,
       r.source_batch_id,
       r.rule_code,
       q.rule_name,
       r.severity,
       q.rule_type,
       r.target_table,
       r.target_column,
       r.total_rows,
       r.failed_rows,
       r.passed_rows,
       r.quality_score,
       r.result_status,
       r.created_at
  FROM dq_result r
  JOIN dq_rule q
    ON q.rule_id = r.rule_id;

CREATE OR REPLACE VIEW vw_dq_batch_summary AS
SELECT dq_batch_id,
       source_batch_id,
       COUNT(*) AS total_rules,
       SUM(CASE WHEN result_status = 'PASS' THEN 1 ELSE 0 END) AS passed_rules,
       SUM(CASE WHEN result_status = 'WARNING' THEN 1 ELSE 0 END) AS warning_rules,
       SUM(CASE WHEN result_status = 'FAIL' THEN 1 ELSE 0 END) AS failed_rules,
       ROUND(AVG(quality_score), 4) AS avg_quality_score,
       CASE
           WHEN SUM(CASE WHEN result_status = 'FAIL' THEN 1 ELSE 0 END) > 0 THEN 'FAILED'
           WHEN SUM(CASE WHEN result_status = 'WARNING' THEN 1 ELSE 0 END) > 0 THEN 'WARNING'
           ELSE 'PASSED'
       END AS dq_status
  FROM dq_result
 GROUP BY dq_batch_id,
          source_batch_id;

CREATE OR REPLACE VIEW vw_latest_dq_health AS
WITH latest_dq AS (
    SELECT MAX(batch_id) AS dq_batch_id
      FROM etl_batch
     WHERE batch_name = 'DATA_QUALITY_CHECK'
)
SELECT s.dq_batch_id,
       s.source_batch_id,
       s.total_rules,
       s.passed_rules,
       s.warning_rules,
       s.failed_rules,
       s.avg_quality_score,
       s.dq_status,
       b.status AS batch_status,
       b.started_at,
       b.ended_at
  FROM vw_dq_batch_summary s
  JOIN latest_dq l
    ON l.dq_batch_id = s.dq_batch_id
  JOIN etl_batch b
    ON b.batch_id = s.dq_batch_id;

CREATE OR REPLACE VIEW vw_dq_failed_rules AS
SELECT *
  FROM vw_dq_rule_results
 WHERE result_status IN ('FAIL', 'WARNING');

PROMPT Data quality views created.
