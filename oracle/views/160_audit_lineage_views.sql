PROMPT Creating audit lineage views...

CREATE OR REPLACE VIEW vw_trade_lineage_detail AS
SELECT l.lineage_run_id,
       l.source_batch_id,
       l.stg_trade_id,
       l.external_trade_id,
       l.source_system,
       l.staging_status,
       l.trade_id,
       l.trade_status,
       l.event_count,
       l.lineage_status,
       l.raw_created_at,
       l.processed_at,
       l.trade_created_at,
       l.last_event_at,
       l.created_at AS lineage_created_at
  FROM audit_lineage_trade l;
/

CREATE OR REPLACE VIEW vw_lineage_timeline AS
SELECT t.lineage_run_id,
       t.source_batch_id,
       t.stg_trade_id,
       t.external_trade_id,
       s.step_name,
       s.step_status,
       s.step_message,
       s.step_timestamp
  FROM audit_lineage_trade t
  JOIN audit_lineage_step s
    ON s.lineage_id = t.lineage_id;
/

CREATE OR REPLACE VIEW vw_latest_lineage_health AS
WITH latest_run AS (
    SELECT MAX(lineage_run_id) AS lineage_run_id
      FROM audit_lineage_run
)
SELECT r.lineage_run_id,
       r.source_batch_id,
       r.status,
       r.total_rows,
       r.complete_rows,
       r.rejected_source_rows,
       r.incomplete_rows,
       CASE
           WHEN r.status = 'SUCCESS' AND r.incomplete_rows = 0 THEN 'HEALTHY'
           WHEN r.status = 'SUCCESS' AND r.incomplete_rows > 0 THEN 'WARNING'
           ELSE 'FAILED'
       END AS lineage_health,
       r.started_at,
       r.ended_at
  FROM audit_lineage_run r
  JOIN latest_run lr
    ON lr.lineage_run_id = r.lineage_run_id;
/

CREATE OR REPLACE VIEW vw_trade_full_journey AS
SELECT s.batch_id AS source_batch_id,
       s.stg_trade_id,
       s.external_trade_id,
       s.source_system,
       s.processing_status,
       s.error_count,
       t.trade_id,
       t.trade_status,
       t.notional_amount,
       t.amount_eur,
       COUNT(e.trade_event_id) AS event_count,
       MAX(e.created_at) AS last_event_at
  FROM stg_trade_raw s
  LEFT JOIN trade t
    ON t.external_trade_id = s.external_trade_id
   AND t.source_system = s.source_system
  LEFT JOIN trade_event e
    ON e.trade_id = t.trade_id
 GROUP BY s.batch_id,
          s.stg_trade_id,
          s.external_trade_id,
          s.source_system,
          s.processing_status,
          s.error_count,
          t.trade_id,
          t.trade_status,
          t.notional_amount,
          t.amount_eur;
/

PROMPT Audit lineage views created.
