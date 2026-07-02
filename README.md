# Mini BOP - Financial Trade Processing Platform

Mini BOP is a didactic financial trade-processing lab inspired by investment-banking data platforms.

The project demonstrates an end-to-end data engineering workflow:

```text
Oracle PL/SQL
  → Oracle export engine
  → HDFS landing zone
  → Hive external tables
  → Spark processing
  → Spark SQL analytics
  → Incremental processing
  → Airflow orchestration
  → Observability and monitoring
  → FastAPI / Swagger / Dashboard
```

## Current status

| Area | Status |
|---|---|
| Oracle core pipeline | Complete |
| Bulk load, partitioning, reconciliation, recovery and data quality | Complete |
| Audit, lineage and configuration-driven pipeline | Complete |
| Oracle → Hadoop export | Complete |
| Hive external query layer | Complete |
| Spark processing and analytics | Complete |
| Incremental processing concepts | Complete |
| Airflow orchestration | Complete |
| Observability and monitoring | Complete |
| REST API, Swagger and dashboard | Complete |
| Local platform packaging | Complete |

## Local quick start

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash scripts/platform/260_check_environment.sh
bash scripts/platform/261_start_local_platform.sh
```

Start the API:

```bash
bash api/scripts/251_run_api.sh
```

Open:

```text
http://localhost:8010/docs
http://localhost:8010/dashboard
```

## Phase 26

The final packaging model is local WSL packaging. The focus is to make the validated data platform easy to start, validate and demonstrate using repeatable local commands.

See:

```text
docs/phase26_platform_packaging_deployment.md
```
