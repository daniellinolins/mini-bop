# Mini BOP - Phase 23 - Airflow Orchestration

## Objective

Phase 23 introduces Apache Airflow as the orchestration layer for the Mini BOP data engineering pipeline.

It does not replace Oracle, Hadoop, Hive or Spark. Instead, it coordinates the operational sequence that has already been validated in previous phases.

## DAG

DAG id:

```text
mini_bop_end_to_end_pipeline
```

## Orchestrated flow

```text
start
  -> check_environment
  -> hdfs_and_hive_layer
       -> create_hdfs_dirs
       -> upload_oracle_exports_to_hdfs
       -> run_hive_phase19
       -> validate_hive_phase19
  -> spark_processing_layer
       -> run_spark_phase20
       -> validate_spark_phase20
       -> run_spark_phase21
       -> validate_spark_phase21
       -> run_spark_phase22
       -> validate_spark_phase22
  -> final_hdfs_inventory
  -> end
```

## Why BashOperator?

The platform intentionally uses BashOperator because each previous phase already has operational shell scripts. This keeps orchestration transparent and close to real production runbooks.

## Concepts demonstrated

- DAG orchestration
- Task dependency management
- TaskGroup organization
- retries
- execution timeout
- environment variables
- manual triggering
- validation tasks
- end-to-end data pipeline control

## Installation

From the project root:

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop

bash airflow/scripts/230_install_airflow_dag.sh
bash airflow/scripts/231_validate_airflow_phase23.sh
```

## Running Airflow services

Terminal 1:

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
airflow webserver --port 8080
```

Terminal 2:

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
airflow scheduler
```

Browser:

```text
http://localhost:8080
```

Credentials:

```text
admin / admin
```

## Trigger

CLI:

```bash
bash airflow/scripts/232_trigger_airflow_phase23.sh
```

Or trigger manually from the Airflow UI.

## Notes

This phase assumes that Phase 18 Oracle export files already exist in:

```text
data/export
```

If they do not exist, run the Oracle Phase 18 export first from SQLPlus.
