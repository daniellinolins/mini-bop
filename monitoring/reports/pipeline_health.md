# Mini BOP - Pipeline Health Report

Generated at: `2026-07-03T17:29:24.742044+00:00`
Overall status: **HEALTHY**

## Checks

| Check | Status | Rows / Details |
|---|---:|---|
| `analytics_gold_dashboard_metrics` | OK | rows=5 |
| `analytics_silver_trade_enriched` | OK | rows=5 |
| `business_incremental_metrics` | OK |  |
| `business_no_duplicate_current_trades` | OK | duplicate_keys=0 |
| `hdfs_analytics_layer` | OK | exists=True |
| `hdfs_hive_layer` | OK | exists=True |
| `hdfs_incremental_layer` | OK | exists=True |
| `hdfs_spark_layer` | OK | exists=True |
| `hdfs_trade_landing` | OK | exists=True |
| `incremental_bronze_batches` | OK | rows=7 |
| `incremental_change_log` | OK | rows=7 |
| `incremental_checkpoint` | OK | rows=1; last_batch=2 |
| `incremental_currency_summary` | OK | rows=2 |
| `incremental_current_trades` | OK | rows=6 |
| `incremental_job_history` | OK | rows=3 |
| `incremental_metrics` | OK | rows=5 |
| `incremental_trade_history` | OK | rows=7 |
| `spark_summary_by_currency` | OK | rows=2 |
| `spark_trade_curated` | OK | rows=5 |

## Interpretation

This report validates the operational health of the Mini BOP data platform across HDFS, Spark curated outputs, analytics datasets, incremental datasets, checkpoints and business-level duplicate controls.
