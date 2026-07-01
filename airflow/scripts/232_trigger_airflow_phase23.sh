#!/usr/bin/env bash
set -euo pipefail

export AIRFLOW_HOME="${AIRFLOW_HOME:-$HOME/airflow-mini-bop/airflow_home}"
export MINI_BOP_PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"

DAG_ID="mini_bop_end_to_end_pipeline"
RUN_ID="manual__mini_bop_phase23_$(date +%Y%m%d%H%M%S)"

echo "Triggering DAG: $DAG_ID"
echo "Run id: $RUN_ID"

airflow dags unpause "$DAG_ID" || true
airflow dags trigger "$DAG_ID" --run-id "$RUN_ID"

echo "Triggered. Use the Airflow UI or run:"
echo "airflow dags state $DAG_ID <execution_date>"
