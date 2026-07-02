# Mini BOP - Phase 26: Local Platform Packaging & Demo Readiness

## Goal

Phase 26 packages the already validated Mini BOP local platform so it can be started, checked and demonstrated with repeatable commands.

The goal is not to change the architecture. The goal is to make the local WSL-based platform easier to operate during demos and interviews.

## Final local architecture

```text
Oracle PL/SQL pipeline
        ↓
Oracle CSV export
        ↓
HDFS landing zone
        ↓
Hive external tables
        ↓
Spark processing
        ↓
Spark SQL analytics
        ↓
Incremental layer
        ↓
Airflow orchestration
        ↓
Monitoring reports
        ↓
FastAPI + Swagger + Dashboard
```

## What this phase delivers

```text
config/mini-bop.local.env.example
scripts/platform/260_check_environment.sh
scripts/platform/261_start_local_platform.sh
scripts/platform/262_validate_platform_packaging.sh
api/scripts/250_install_api_deps.sh
api/scripts/251_run_api.sh
api/scripts/252_validate_api_phase25.sh
docs/phase26_platform_packaging_deployment.md
README.md
```

## One-time setup

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop

bash api/scripts/250_install_api_deps.sh
```

## Check the environment

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash scripts/platform/260_check_environment.sh
```

## Start the local platform

```bash
bash scripts/platform/261_start_local_platform.sh
```

This checks/starts HDFS and YARN, validates key HDFS paths and prints the recommended commands for Airflow and the API.

## Refresh monitoring reports

```bash
bash monitoring/scripts/240_collect_pipeline_metrics.sh
bash monitoring/scripts/241_validate_monitoring_phase24.sh
```

## Start the API

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash api/scripts/251_run_api.sh
```

Open:

```text
http://localhost:8010/docs
http://localhost:8010/dashboard
```

## Validate API

In another terminal:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_BASE=http://localhost:8010

bash api/scripts/252_validate_api_phase25.sh
```

## Validate Phase 26

```bash
bash scripts/platform/262_validate_platform_packaging.sh
```

Expected:

```text
PHASE26_LOCAL_PLATFORM_PACKAGING_STATUS=PASSED
```

## Demo positioning

This phase demonstrates deployment discipline without adding unnecessary infrastructure complexity to the local lab. The project now has repeatable commands for environment validation, platform startup, monitoring refresh and API execution.

For a technical interview, this gives a clean and credible demo flow:

```text
check environment
start platform
refresh monitoring
start API
open Swagger
open dashboard
explain architecture
```
