#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 20"
echo "============================================================"

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
OUTPUT_ROOT="hdfs://localhost:9000/data/mini_bop/spark"
VALIDATION_JOB="$PROJECT_ROOT/spark/jobs/201_validate_spark_outputs.py"

echo "1) Hadoop processes"
jps

echo "2) Spark version"
spark-submit --version

echo "3) HDFS Spark outputs"
hdfs dfs -ls /data/mini_bop/spark
hdfs dfs -ls /data/mini_bop/spark/trade_curated
hdfs dfs -ls /data/mini_bop/spark/trade_summary_by_currency
hdfs dfs -ls /data/mini_bop/spark/trade_summary_by_buy_sell
hdfs dfs -ls /data/mini_bop/spark/trade_quality_metrics

echo "4) Reading Spark Parquet outputs with spark-submit"
spark-submit \
  --master local[*] \
  "$VALIDATION_JOB" \
  --output-root "$OUTPUT_ROOT"

echo "Phase 20 validation completed."
