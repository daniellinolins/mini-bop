#!/usr/bin/env bash
set -euo pipefail

: "${AIRFLOW_HOME:?AIRFLOW_HOME must be set}"
PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"
DAGS_DIR="$AIRFLOW_HOME/dags"
mkdir -p "$DAGS_DIR"
cp "$PROJECT_ROOT/airflow/dags/mini_bop_orchestration_dag.py" "$DAGS_DIR/mini_bop_orchestration_dag.py"
chmod +x "$DAGS_DIR/mini_bop_orchestration_dag.py"
echo "DAG installed at: $DAGS_DIR/mini_bop_orchestration_dag.py"
echo "PROJECT_ROOT=$PROJECT_ROOT"
