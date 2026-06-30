PROMPT Creating metadata engine views...

CREATE OR REPLACE VIEW vw_md_rule_catalog AS
SELECT rg.rule_group_code,
       rg.rule_group_name,
       rd.rule_id,
       rd.rule_code,
       rd.rule_name,
       rd.target_table,
       rd.target_column,
       rd.rule_type,
       rd.severity,
       rd.failure_condition,
       rd.active_flag,
       rd.execution_order
  FROM md_rule_group rg
  JOIN md_rule_definition rd ON rd.rule_group_id = rg.rule_group_id;

CREATE OR REPLACE VIEW vw_md_execution_summary AS
SELECT e.execution_id,
       e.batch_id,
       e.source_batch_id,
       e.rule_group_code,
       e.status,
       e.total_rules,
       e.passed_rules,
       e.warning_rules,
       e.failed_rules,
       e.avg_score,
       e.started_at,
       e.ended_at,
       ROUND((CAST(e.ended_at AS DATE) - CAST(e.started_at AS DATE)) * 86400000, 0) AS elapsed_ms
  FROM md_rule_execution e;

CREATE OR REPLACE VIEW vw_md_rule_results AS
SELECT e.execution_id,
       e.batch_id,
       e.source_batch_id,
       e.rule_group_code,
       r.rule_code,
       d.rule_name,
       d.rule_type,
       r.severity,
       r.total_rows,
       r.failed_rows,
       r.passed_rows,
       r.quality_score,
       r.result_status,
       r.error_message,
       r.created_at
  FROM md_rule_execution e
  JOIN md_rule_execution_result r ON r.execution_id = e.execution_id
  JOIN md_rule_definition d ON d.rule_id = r.rule_id;

CREATE OR REPLACE VIEW vw_latest_md_engine_health AS
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
       CASE
           WHEN status = 'FAILED' THEN 'FAILED'
           WHEN failed_rules > 0 THEN 'FAILED'
           WHEN warning_rules > 0 THEN 'WARNING'
           ELSE 'HEALTHY'
       END AS health_status,
       started_at,
       ended_at
  FROM vw_md_execution_summary
 WHERE execution_id = (SELECT MAX(execution_id) FROM md_rule_execution);

CREATE OR REPLACE VIEW vw_md_failed_rules AS
SELECT *
  FROM vw_md_rule_results
 WHERE result_status IN ('FAIL', 'WARNING', 'ERROR');

PROMPT Metadata engine views created.
