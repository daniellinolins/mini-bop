#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INPUT_PATH="hdfs://localhost:9000/data/mini_bop/hive/trade_core_csv"
OUTPUT_ROOT="hdfs://localhost:9000/data/mini_bop/spark"

cd "$PROJECT_ROOT"

echo "============================================================"
echo "MINI BOP - PHASE 20"
echo "SPARK PROCESSING ENGINE"
echo "============================================================"
echo "Project root: $PROJECT_ROOT"
echo "Input path:   $INPUT_PATH"
echo "Output root:  $OUTPUT_ROOT"

echo "Checking Hadoop processes..."
jps

echo "Checking HDFS input files..."
hdfs dfs -ls /data/mini_bop/hive/trade_core_csv

echo "Preparing Spark output directory..."
hdfs dfs -mkdir -p /data/mini_bop/spark

echo "Running Spark job..."
spark-submit \
  --master local[*] \
  --conf spark.hadoop.fs.defaultFS=hdfs://localhost:9000 \
  spark/jobs/200_trade_processing_engine.py \
  "$INPUT_PATH" \
  "$OUTPUT_ROOT"

echo "Spark Phase 20 execution completed."
