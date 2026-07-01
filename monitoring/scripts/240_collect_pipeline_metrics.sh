#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPORT_DIR="$PROJECT_ROOT/monitoring/reports"
PY_SCRIPT="$PROJECT_ROOT/monitoring/python/240_generate_monitoring_report.py"

mkdir -p "$REPORT_DIR"

echo "============================================================"
echo "MINI BOP - PHASE 24"
echo "OBSERVABILITY & MONITORING"
echo "============================================================"
echo "Project root: $PROJECT_ROOT"
echo "Report dir:   $REPORT_DIR"

cd "$PROJECT_ROOT"

echo "1) Capturing Hadoop JVM processes..."
jps | tee "$REPORT_DIR/jps_status.txt"

echo "2) Capturing HDFS inventory..."
{
  echo "# HDFS Inventory - Mini BOP"
  date '+generated_at=%Y-%m-%d %H:%M:%S'
  echo
  for path in \
    /data/mini_bop \
    /data/mini_bop/trade \
    /data/mini_bop/hive \
    /data/mini_bop/spark \
    /data/mini_bop/analytics \
    /data/mini_bop/incremental
  do
    echo "## $path"
    hdfs dfs -ls -R "$path" 2>&1 || true
    echo
  done
} | tee "$REPORT_DIR/hdfs_inventory.txt"

echo "3) Capturing Airflow DAG status if available..."
{
  echo "# Airflow DAG Status"
  date '+generated_at=%Y-%m-%d %H:%M:%S'
  echo
  if command -v airflow >/dev/null 2>&1; then
    airflow dags list 2>&1 || true
    echo
    airflow dags list-runs -d mini_bop_end_to_end_pipeline 2>&1 || true
  else
    echo "airflow command not found in current shell"
  fi
} | tee "$REPORT_DIR/airflow_dag_status.txt"

echo "4) Generating structured monitoring report..."
spark-submit "$PY_SCRIPT" \
  --project-root "$PROJECT_ROOT" \
  --report-dir "$REPORT_DIR" \
  --hdfs-root "hdfs://localhost:9000/data/mini_bop" \
  --incremental-root "hdfs://localhost:9000/data/mini_bop/incremental" \
  --analytics-root "hdfs://localhost:9000/data/mini_bop/analytics" \
  --spark-root "hdfs://localhost:9000/data/mini_bop/spark"

echo "============================================================"
echo "PHASE 24 REPORTS CREATED"
echo "============================================================"
ls -la "$REPORT_DIR"

echo "Phase 24 monitoring collection completed."
