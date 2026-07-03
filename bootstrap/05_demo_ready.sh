#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
API_PORT="${MINI_BOP_API_PORT:-8010}"
AIRFLOW_PORT="${AIRFLOW_PORT:-8080}"

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }

print_section "MINI BOP - BOOTSTRAP 05 - DEMO READY CHECKLIST"

echo "Project root: $PROJECT_ROOT"
echo ""
echo "Open these URLs:"
echo "- Airflow UI : http://localhost:$AIRFLOW_PORT"
echo "- API docs   : http://localhost:$API_PORT/docs"
echo "- Dashboard  : http://localhost:$API_PORT/dashboard"
echo ""
echo "Suggested demo flow:"
echo "1. Show README and architecture overview."
echo "2. Show HDFS landing and analytical layers."
echo "3. Show Airflow DAG mini_bop_end_to_end_pipeline."
echo "4. Show monitoring report and HEALTHY status."
echo "5. Open Swagger and test /health, /pipeline/status, /trades/top."
echo "6. Open dashboard and explain exposure, top trades and health checks."
echo ""
echo "Quick terminal checks:"
echo "hdfs dfs -ls /data/mini_bop"
echo "bash monitoring/scripts/241_validate_monitoring_phase24.sh"
echo "bash api/scripts/252_validate_api_phase25.sh"
echo ""
echo "BOOTSTRAP_05_DEMO_READY_STATUS=COMPLETED"
