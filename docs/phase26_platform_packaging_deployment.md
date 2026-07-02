# Mini BOP - Phase 26: Platform Packaging & Deployment

## Goal

Phase 26 packages the Mini BOP data platform so it is easier to run, validate and demonstrate.

The project already includes Oracle processing, Hadoop/HDFS, Hive, Spark, Airflow, monitoring, FastAPI and a dashboard. This phase adds a professional deployment layer around those components.

## Scope

This phase does **not** move Hadoop/Hive/Spark into Docker. They remain local services in WSL, because they were already installed and validated in previous phases.

This phase does package:

- FastAPI application container definition.
- Environment variable template.
- Docker Compose for the API layer.
- Local platform bootstrap/check scripts.
- Deployment documentation.

## Files

```text
docker/api/Dockerfile
docker/env/mini-bop.env.example
docker-compose.api.yml
scripts/platform/260_check_environment.sh
scripts/platform/261_start_local_platform.sh
scripts/platform/262_validate_platform_packaging.sh
docs/phase26_platform_packaging_deployment.md
```

## Local WSL execution

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010
bash scripts/platform/260_check_environment.sh
bash scripts/platform/261_start_local_platform.sh
bash api/scripts/251_run_api.sh
```

Open:

```text
http://localhost:8010/docs
http://localhost:8010/dashboard
```

## Docker API execution

The Docker API container expects Hadoop/HDFS to be reachable from the container host.

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
docker compose -f docker-compose.api.yml build
docker compose -f docker-compose.api.yml up -d
```

Open:

```text
http://localhost:8010/docs
```

Stop:

```bash
docker compose -f docker-compose.api.yml down
```

## Validation

```bash
bash scripts/platform/262_validate_platform_packaging.sh
```

Expected result:

```text
PHASE26_PLATFORM_PACKAGING_STATUS=PASSED
```

## Enterprise positioning

This phase demonstrates environment packaging, deployment discipline and operational readiness. It complements Airflow orchestration and monitoring with repeatable startup and validation commands.
