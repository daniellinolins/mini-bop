#!/usr/bin/env bash
set -euo pipefail

 echo "============================================================"
 echo "MINI BOP - START LOCAL PLATFORM"
 echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
API_PORT=${MINI_BOP_API_PORT:-8010}
AIRFLOW_HOME=${AIRFLOW_HOME:-$HOME/airflow-mini-bop/airflow_home}
cd "$PROJECT_ROOT"

 echo "Project root: $PROJECT_ROOT"
 echo "API port:     $API_PORT"
 echo

if command -v start-dfs.sh >/dev/null 2>&1; then
  echo "Starting HDFS..."
  start-dfs.sh || true
else
  echo "WARN: start-dfs.sh not found"
fi

if command -v start-yarn.sh >/dev/null 2>&1; then
  echo "Starting YARN..."
  start-yarn.sh || true
else
  echo "WARN: start-yarn.sh not found"
fi

 echo
 echo "Current JVM processes:"
jps || true

 echo
 echo "Checking HDFS root:"
hdfs dfs -ls /data/mini_bop || true

 echo
 echo "Refreshing monitoring report if possible..."
if [ -x monitoring/scripts/240_collect_pipeline_metrics.sh ]; then
  bash monitoring/scripts/240_collect_pipeline_metrics.sh || true
else
  echo "WARN: monitoring collector not found or not executable"
fi

 echo
 echo "============================================================"
 echo "NEXT COMMANDS"
 echo "============================================================"
 echo
 echo "Airflow UI - terminal 1:"
 echo "  source ~/airflow-mini-bop/.venv/bin/activate"
 echo "  export AIRFLOW_HOME=$AIRFLOW_HOME"
 echo "  airflow webserver --port 8080"
 echo
 echo "Airflow scheduler - terminal 2:"
 echo "  source ~/airflow-mini-bop/.venv/bin/activate"
 echo "  export AIRFLOW_HOME=$AIRFLOW_HOME"
 echo "  airflow scheduler"
 echo
 echo "FastAPI - terminal 3:"
 echo "  cd $PROJECT_ROOT"
 echo "  source ~/airflow-mini-bop/.venv/bin/activate"
 echo "  export MINI_BOP_PROJECT_ROOT=$PROJECT_ROOT"
 echo "  export MINI_BOP_API_PORT=$API_PORT"
 echo "  bash api/scripts/251_run_api.sh"
 echo
 echo "Browser:"
 echo "  http://localhost:$API_PORT/docs"
 echo "  http://localhost:$API_PORT/dashboard"
