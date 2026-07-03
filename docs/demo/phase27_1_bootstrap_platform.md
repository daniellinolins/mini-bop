# Phase 27.1 — Bootstrap Platform

## Purpose

The goal of Phase 27.1 is to make the Mini BOP platform easier to start, validate and present during a technical demo.

Instead of requiring the presenter to remember many independent commands, this phase introduces a `bootstrap/` folder with ordered scripts.

## Bootstrap sequence

| Step | Script | Purpose |
|---|---|---|
| 00 | `00_check_environment.sh` | Checks Java, Hadoop, Hive, Spark, Airflow, Python and project folders. |
| 01 | `01_start_hadoop.sh` | Starts HDFS and YARN if they are not already running. |
| 02 | `02_start_airflow.sh` | Installs/validates the Airflow DAG and prints commands to start UI/scheduler. |
| 03 | `03_start_api.sh` | Refreshes monitoring reports and starts FastAPI locally. |
| 04 | `04_validate_platform.sh` | Runs monitoring and API validations. |
| 05 | `05_demo_ready.sh` | Prints demo URLs and suggested presentation flow. |
| 06 | `06_stop_platform.sh` | Stops Hadoop/YARN services. |

## Design decision

This project intentionally uses local platform packaging instead of Docker packaging.

Reason: the project demonstrates an end-to-end data engineering platform based on Oracle, Hadoop, Hive, Spark, Airflow, monitoring and FastAPI. Keeping Hadoop/Spark local in WSL reduces container complexity and keeps the demo focused on data engineering capabilities.

## Demo URLs

- Airflow: `http://localhost:8080`
- Swagger/OpenAPI: `http://localhost:8010/docs`
- Dashboard: `http://localhost:8010/dashboard`

## Expected validation result

```text
BOOTSTRAP_04_PLATFORM_VALIDATION_STATUS=PASSED
```
