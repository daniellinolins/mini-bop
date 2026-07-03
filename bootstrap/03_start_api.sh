#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export MINI_BOP_PROJECT_ROOT="$PROJECT_ROOT"
export MINI_BOP_API_PORT="${MINI_BOP_API_PORT:-8010}"
AIRFLOW_VENV="${AIRFLOW_VENV:-$HOME/airflow-mini-bop/.venv}"

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }

print_section "MINI BOP - BOOTSTRAP 03 - START REST API"
echo "Project root : $PROJECT_ROOT"
echo "API port     : $MINI_BOP_API_PORT"

if [ ! -f "$AIRFLOW_VENV/bin/activate" ]; then
  echo "ERROR: Python virtualenv not found at $AIRFLOW_VENV"
  exit 1
fi

# shellcheck source=/dev/null
source "$AIRFLOW_VENV/bin/activate"

mkdir -p "$HOME/spark-tmp"
export TMPDIR="$HOME/spark-tmp"
export SPARK_LOCAL_DIRS="$HOME/spark-tmp"
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$HOME/spark-tmp ${JAVA_TOOL_OPTIONS:-}"

if [ -f "$PROJECT_ROOT/monitoring/scripts/240_collect_pipeline_metrics.sh" ]; then
  echo "Refreshing monitoring report before API startup..."
  bash "$PROJECT_ROOT/monitoring/scripts/240_collect_pipeline_metrics.sh" || true
fi

echo "Starting API..."
bash "$PROJECT_ROOT/api/scripts/251_run_api.sh"
