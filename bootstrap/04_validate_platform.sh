#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
export MINI_BOP_PROJECT_ROOT="$PROJECT_ROOT"
export MINI_BOP_API_PORT="${MINI_BOP_API_PORT:-8010}"
export MINI_BOP_API_BASE="${MINI_BOP_API_BASE:-http://localhost:${MINI_BOP_API_PORT}}"
AIRFLOW_VENV="${AIRFLOW_VENV:-$HOME/airflow-mini-bop/.venv}"

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }

print_section "MINI BOP - BOOTSTRAP 04 - VALIDATE PLATFORM"

if [ -f "$AIRFLOW_VENV/bin/activate" ]; then
  # shellcheck source=/dev/null
  source "$AIRFLOW_VENV/bin/activate"
fi

print_section "Hadoop/HDFS"
jps || true
hdfs dfs -ls /data/mini_bop || true

print_section "Phase 24 monitoring validation"
bash "$PROJECT_ROOT/monitoring/scripts/241_validate_monitoring_phase24.sh"

print_section "Phase 25 API validation"
bash "$PROJECT_ROOT/api/scripts/252_validate_api_phase25.sh"

echo "BOOTSTRAP_04_PLATFORM_VALIDATION_STATUS=PASSED"
