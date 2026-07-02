#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "MINI BOP - START LOCAL PLATFORM"
echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
API_PORT=${MINI_BOP_API_PORT:-8010}
cd "$PROJECT_ROOT"

if command -v start-dfs.sh >/dev/null 2>&1; then
  echo "Starting HDFS..."
  start-dfs.sh || true
fi

if command -v start-yarn.sh >/dev/null 2>&1; then
  echo "Starting YARN..."
  start-yarn.sh || true
fi

echo "Current JVM processes:"
jps || true

echo "Checking HDFS landing area..."
hdfs dfs -ls /data/mini_bop || true

echo
echo "To start Airflow UI manually, open two terminals:"
echo "  source ~/airflow-mini-bop/.venv/bin/activate"
echo "  export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home"
echo "  airflow webserver --port 8080"
echo
echo "  source ~/airflow-mini-bop/.venv/bin/activate"
echo "  export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home"
echo "  airflow scheduler"
echo
echo "To start API locally:"
echo "  source ~/airflow-mini-bop/.venv/bin/activate"
echo "  export MINI_BOP_PROJECT_ROOT=$PROJECT_ROOT"
echo "  export MINI_BOP_API_PORT=$API_PORT"
echo "  bash api/scripts/251_run_api.sh"
