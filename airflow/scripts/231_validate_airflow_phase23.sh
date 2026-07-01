#!/usr/bin/env bash
set -euo pipefail

: "${AIRFLOW_HOME:?AIRFLOW_HOME must be set}"
export MINI_BOP_PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"
DAG_ID="mini_bop_end_to_end_pipeline"

printf '%s
' '============================================================'
printf '%s
' 'VALIDATING MINI BOP - PHASE 23.1'
printf '%s
' 'AIRFLOW ORCHESTRATION REFINEMENT'
printf '%s
' '============================================================'

echo '1) Airflow version'
airflow version

echo '2) DAG import errors'
airflow dags list-import-errors

echo '3) DAG list'
airflow dags list | grep "$DAG_ID"

echo '4) DAG tasks'
airflow tasks list "$DAG_ID" --tree

echo '5) Task dry-run: check_environment'
airflow tasks test "$DAG_ID" check_environment 2026-07-01

echo 'AIRFLOW_PHASE23_REFINEMENT_STATUS=PASSED'
