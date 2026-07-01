#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
ANALYTICS_ROOT="hdfs://localhost:9000/data/mini_bop/analytics"
VALIDATION_JOB="$PROJECT_ROOT/spark/jobs/211_validate_spark_sql_analytics.py"

printf '%s\n' '============================================================'
printf '%s\n' 'VALIDATING MINI BOP - PHASE 21'
printf '%s\n' '============================================================'

printf '%s\n' '1) Hadoop processes'
jps || true

printf '%s\n' '2) Spark version'
spark-submit --version

printf '%s\n' '3) Analytics HDFS outputs'
hdfs dfs -ls /data/mini_bop/analytics
hdfs dfs -ls /data/mini_bop/analytics/silver_trade_enriched
hdfs dfs -ls /data/mini_bop/analytics/gold_exposure_by_currency
hdfs dfs -ls /data/mini_bop/analytics/gold_exposure_by_book
hdfs dfs -ls /data/mini_bop/analytics/gold_exposure_by_portfolio
hdfs dfs -ls /data/mini_bop/analytics/gold_exposure_by_counterparty
hdfs dfs -ls /data/mini_bop/analytics/gold_top_trades_by_amount
hdfs dfs -ls /data/mini_bop/analytics/gold_dashboard_metrics

printf '%s\n' '4) Reading analytics Parquet outputs with spark-submit'
spark-submit \
  --master local[*] \
  "$VALIDATION_JOB" \
  --analytics-root "$ANALYTICS_ROOT"

printf '%s\n' 'Phase 21 validation completed.'
