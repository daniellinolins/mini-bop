# Phase 23.1 - Airflow Orchestration Refinement

Refines the Mini BOP Airflow DAG after UI validation.

## Improvements

- Removed BashOperator `TemplateNotFound` warnings by setting `template_ext=()`.
- Added reusable `mini_bop_bash()` task factory.
- Added execution timeouts per task.
- Added retry policy and retry delay.
- Disabled email on failure/retry for the local platform.
- Added `doc_md` at DAG and task level to improve Airflow UI presentation.
- Kept the DAG manually triggered with `schedule_interval=None`.

## Validation

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop

bash airflow/scripts/230_install_airflow_dag.sh
bash airflow/scripts/231_validate_airflow_phase23.sh
```

Expected:

```text
AIRFLOW_PHASE23_REFINEMENT_STATUS=PASSED
```
