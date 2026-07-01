#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_ROOT="hdfs://localhost:9000/data/mini_bop/incremental"

cd "$PROJECT_ROOT"

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 22"
echo "============================================================"
echo "1) Hadoop processes"
jps

echo "2) Spark version"
spark-submit --version

echo "3) Incremental HDFS outputs"
hdfs dfs -ls /data/mini_bop/incremental
for d in \
  bronze_incremental_batches \
  silver_current_trades \
  silver_trade_history \
  silver_trade_change_log \
  gold_incremental_currency_summary \
  gold_incremental_metrics \
  control_spark_job_history \
  control_incremental_checkpoint; do
  echo "--- $d"
  hdfs dfs -ls "/data/mini_bop/incremental/$d"
done

echo "4) Reading incremental Parquet outputs with spark-submit"
spark-submit spark/jobs/221_validate_incremental_outputs.py "$OUTPUT_ROOT"

echo "Phase 22 validation completed."
