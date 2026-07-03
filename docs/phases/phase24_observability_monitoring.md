# Mini BOP - Phase 24 - Observability & Monitoring

## Goal

Phase 24 adds an operational observability layer to the Mini BOP data platform.
It does not replace Airflow. Airflow orchestrates the pipeline; Phase 24 provides a consolidated health report across HDFS, Spark outputs, analytics layers, incremental processing outputs and control metadata.

## Delivered components

- `monitoring/scripts/240_collect_pipeline_metrics.sh`
- `monitoring/scripts/241_validate_monitoring_phase24.sh`
- `monitoring/python/240_generate_monitoring_report.py`
- `monitoring/reports/` generated at runtime

## Reports generated

- `monitoring/reports/pipeline_health.json`
- `monitoring/reports/pipeline_health.md`
- `monitoring/reports/hdfs_inventory.txt`
- `monitoring/reports/jps_status.txt`
- `monitoring/reports/airflow_dag_status.txt`

## Checks performed

- Hadoop JVM process inventory using `jps`
- HDFS directory inventory
- Airflow DAG status when Airflow is available in the shell
- Spark Parquet row counts for curated, analytics and incremental datasets
- Incremental checkpoint validation
- Duplicate business key validation on current trades
- Business metric validation for incremental current trades

## Expected status

The validation script expects:

```text
OBSERVABILITY_PHASE24_STATUS=PASSED
```

and the generated JSON report should contain:

```json
"overall_status": "HEALTHY"
```

## How to run

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop

bash monitoring/scripts/240_collect_pipeline_metrics.sh
bash monitoring/scripts/241_validate_monitoring_phase24.sh
```

## Interview talking points

This phase demonstrates production-oriented thinking:

- not only building pipelines, but operating them;
- not only processing data, but validating platform health;
- not only producing outputs, but exposing metrics and reports;
- readiness for alerts, dashboards and operational monitoring.


## Phase 24.1 Fixes

- Corrected the business incremental metrics check to read `CURRENT_TRADE_ROWS` from `gold_incremental_metrics`.
- Removed the unsupported `--limit` option from `airflow dags list-runs` for Airflow 2.10 compatibility.
