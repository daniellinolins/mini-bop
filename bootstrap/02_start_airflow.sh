#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export MINI_BOP_PROJECT_ROOT="$PROJECT_ROOT"
export AIRFLOW_HOME="${AIRFLOW_HOME:-$HOME/airflow-mini-bop/airflow_home}"
AIRFLOW_VENV="${AIRFLOW_VENV:-$HOME/airflow-mini-bop/.venv}"
AIRFLOW_PORT="${AIRFLOW_PORT:-8080}"

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }

print_section "MINI BOP - BOOTSTRAP 02 - START AIRFLOW"
echo "Project root : $PROJECT_ROOT"
echo "AIRFLOW_HOME : $AIRFLOW_HOME"
echo "Airflow port : $AIRFLOW_PORT"

if [ ! -f "$AIRFLOW_VENV/bin/activate" ]; then
  echo "ERROR: Airflow virtualenv not found at $AIRFLOW_VENV"
  exit 1
fi

# shellcheck source=/dev/null
source "$AIRFLOW_VENV/bin/activate"

mkdir -p "$AIRFLOW_HOME/dags" "$AIRFLOW_HOME/logs"

if [ -f "$PROJECT_ROOT/airflow/scripts/230_install_airflow_dag.sh" ]; then
  bash "$PROJECT_ROOT/airflow/scripts/230_install_airflow_dag.sh"
fi

print_section "Airflow DAGs"
airflow dags list || true

echo ""
echo "To start Airflow UI and scheduler, open two WSL terminals:"
echo ""
echo "Terminal A:"
echo "source $AIRFLOW_VENV/bin/activate"
echo "export AIRFLOW_HOME=$AIRFLOW_HOME"
echo "export MINI_BOP_PROJECT_ROOT=$PROJECT_ROOT"
echo "airflow webserver --port $AIRFLOW_PORT"
echo ""
echo "Terminal B:"
echo "source $AIRFLOW_VENV/bin/activate"
echo "export AIRFLOW_HOME=$AIRFLOW_HOME"
echo "export MINI_BOP_PROJECT_ROOT=$PROJECT_ROOT"
echo "airflow scheduler"
echo ""
echo "Airflow URL: http://localhost:$AIRFLOW_PORT"
echo "BOOTSTRAP_02_STATUS=INSTRUCTIONS_PRINTED"
