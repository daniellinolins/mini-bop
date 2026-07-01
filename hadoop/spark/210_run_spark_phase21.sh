#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT_ROOT="hdfs://localhost:9000/data/mini_bop/spark"
OUTPUT_ROOT="hdfs://localhost:9000/data/mini_bop/analytics"
JOB_FILE="$PROJECT_ROOT/spark/jobs/210_spark_sql_analytics_layer.py"

printf '%s\n' '============================================================'
printf '%s\n' 'MINI BOP - PHASE 21'
printf '%s\n' 'SPARK SQL ANALYTICS LAYER'
printf '%s\n' '============================================================'
printf 'Project root: %s\n' "$PROJECT_ROOT"
printf 'Input root:   %s\n' "$INPUT_ROOT"
printf 'Output root:  %s\n' "$OUTPUT_ROOT"

printf '%s\n' 'Checking Hadoop processes...'
jps || true

printf '%s\n' 'Checking Spark Phase 20 inputs...'
hdfs dfs -ls /data/mini_bop/spark/trade_curated

printf '%s\n' 'Preparing analytics output directory...'
hdfs dfs -rm -r -f /data/mini_bop/analytics >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /data/mini_bop/analytics

printf '%s\n' 'Running Spark SQL analytics job...'
spark-submit \
  --master local[*] \
  "$JOB_FILE" \
  --input-root "$INPUT_ROOT" \
  --output-root "$OUTPUT_ROOT"

printf '%s\n' 'Phase 21 Spark SQL analytics execution completed.'
