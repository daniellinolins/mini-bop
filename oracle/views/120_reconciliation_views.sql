PROMPT Creating reconciliation views...

CREATE OR REPLACE VIEW vw_reconciliation_metrics AS
SELECT b.batch_id,
       b.batch_name,
       b.status,
       b.started_at,
       b.ended_at,
       l.module_name,
       REGEXP_SUBSTR(l.message, 'RECON_METRIC\|([^=]+)=', 1, 1, NULL, 1) AS metric_name,
       TO_NUMBER(REGEXP_SUBSTR(l.message, '=(-?[0-9]+(\.[0-9]+)?)', 1, 1, NULL, 1)) AS metric_value,
       l.created_at
  FROM etl_batch b
  JOIN etl_log l
    ON l.batch_id = b.batch_id
 WHERE l.message LIKE 'RECON_METRIC|%';
/

CREATE OR REPLACE VIEW vw_latest_reconciliation_health AS
WITH latest_recon AS (
    SELECT MAX(batch_id) AS batch_id
      FROM etl_batch
     WHERE batch_name = 'RECONCILIATION_BATCH'
), metrics AS (
    SELECT m.metric_name,
           m.metric_value
      FROM vw_reconciliation_metrics m
      JOIN latest_recon lr
        ON lr.batch_id = m.batch_id
)
SELECT MAX(lr.batch_id) AS reconciliation_batch_id,
       MAX(CASE WHEN m.metric_name = 'source_batch_id' THEN m.metric_value END) AS source_batch_id,
       MAX(CASE WHEN m.metric_name = 'total_staging_rows' THEN m.metric_value END) AS total_staging_rows,
       MAX(CASE WHEN m.metric_name = 'processed_staging_rows' THEN m.metric_value END) AS processed_staging_rows,
       MAX(CASE WHEN m.metric_name = 'rejected_staging_rows' THEN m.metric_value END) AS rejected_staging_rows,
       MAX(CASE WHEN m.metric_name = 'loaded_trade_rows' THEN m.metric_value END) AS loaded_trade_rows,
       MAX(CASE WHEN m.metric_name = 'trade_event_rows' THEN m.metric_value END) AS trade_event_rows,
       MAX(CASE WHEN m.metric_name = 'missing_trade_rows' THEN m.metric_value END) AS missing_trade_rows,
       MAX(CASE WHEN m.metric_name = 'missing_event_rows' THEN m.metric_value END) AS missing_event_rows,
       CASE
           WHEN NVL(MAX(CASE WHEN m.metric_name = 'missing_trade_rows' THEN m.metric_value END), 0) = 0
            AND NVL(MAX(CASE WHEN m.metric_name = 'missing_event_rows' THEN m.metric_value END), 0) = 0
           THEN 'RECONCILED'
           ELSE 'DIFFERENCES_FOUND'
       END AS reconciliation_status
  FROM latest_recon lr
  LEFT JOIN metrics m
    ON 1 = 1;
/

CREATE OR REPLACE VIEW vw_trade_reconciliation_detail AS
SELECT s.batch_id,
       s.stg_trade_id,
       s.external_trade_id,
       s.source_system,
       s.processing_status,
       t.trade_id,
       CASE WHEN t.trade_id IS NULL AND s.processing_status = 'PROCESSED' THEN 'MISSING_TRADE'
            WHEN t.trade_id IS NOT NULL AND s.processing_status = 'PROCESSED' THEN 'TRADE_FOUND'
            WHEN s.processing_status = 'REJECTED' THEN 'REJECTED_SOURCE'
            ELSE 'NOT_PROCESSED'
       END AS trade_recon_status,
       COUNT(e.trade_event_id) AS event_count,
       CASE WHEN t.trade_id IS NOT NULL AND COUNT(e.trade_event_id) = 0 THEN 'MISSING_EVENT'
            WHEN t.trade_id IS NOT NULL AND COUNT(e.trade_event_id) > 0 THEN 'EVENT_FOUND'
            WHEN s.processing_status = 'REJECTED' THEN 'EVENT_NOT_REQUIRED'
            ELSE 'NOT_APPLICABLE'
       END AS event_recon_status
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
          t.trade_id;
/

PROMPT Reconciliation views created.
