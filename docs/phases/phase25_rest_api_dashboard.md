# Phase 25 — REST API & Dashboard

This phase exposes Mini BOP analytics outputs through a Python FastAPI application.

## Components

- FastAPI service
- Swagger/OpenAPI docs at `/docs`
- REST endpoints over monitoring, current trades, exposures and checkpoint data
- Simple HTML dashboard at `/dashboard`
- PySpark-backed Parquet/HDFS reader

## Endpoints

- `/health`
- `/pipeline/status`
- `/metrics`
- `/trades/current`
- `/trades/top`
- `/exposure/currency`
- `/exposure/book`
- `/incremental/checkpoint`
- `/monitoring/report`
- `/dashboard`

## Run

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
bash api/scripts/250_install_api_deps.sh
bash api/scripts/251_run_api.sh
```

Validate in another terminal:

```bash
bash api/scripts/252_validate_api_phase25.sh
```
