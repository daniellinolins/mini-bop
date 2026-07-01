#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT_PATH="hdfs://localhost:9000/data/mini_bop/spark/trade_curated"
OUTPUT_ROOT="hdfs://localhost:9000/data/mini_bop/incremental"

cd "$PROJECT_ROOT"

echo "============================================================"
echo "MINI BOP - PHASE 22"
echo "SPARK INCREMENTAL PROCESSING & DELTA LAKE CONCEPTS"
echo "============================================================"
echo "Project root: $PROJECT_ROOT"
echo "Input path:   $INPUT_PATH"
echo "Output root:  $OUTPUT_ROOT"

echo "Checking Hadoop processes..."
jps

echo "Checking Spark Phase 20 curated input..."
hdfs dfs -ls /data/mini_bop/spark/trade_curated

echo "Preparing incremental output directory..."
hdfs dfs -rm -r -f /data/mini_bop/incremental >/dev/null 2>&1 || true
hdfs dfs -mkdir -p /data/mini_bop/incremental

echo "Running Spark incremental job..."
spark-submit spark/jobs/220_spark_incremental_delta_concepts.py "$INPUT_PATH" "$OUTPUT_ROOT"

echo "Phase 22 Spark incremental execution completed."
