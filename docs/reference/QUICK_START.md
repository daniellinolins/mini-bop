# Quick Start

This guide describes how to start the Mini BOP platform locally using the bootstrap scripts.

## Prerequisites

The local environment should include:

- WSL2 with Ubuntu 24.04 or compatible Linux environment.
- Java 11.
- Hadoop 3.4.x.
- Hive 4.x.
- Spark 3.5.x.
- Python 3.12.
- Airflow 2.10.x virtual environment.
- Oracle client/database access for Oracle phases.

## Environment Variables

```bash
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010
export MINI_BOP_API_BASE=http://localhost:8010
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
```

## Step 1 — Validate Environment

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate

bash bootstrap/00_check_environment.sh
```

Expected status:

```text
BOOTSTRAP_00_STATUS=COMPLETED
```

## Step 2 — Start Hadoop and YARN

```bash
bash bootstrap/01_start_hadoop.sh
```

Expected status:

```text
BOOTSTRAP_01_STATUS=COMPLETED
```

Relevant UIs:

- HDFS NameNode: http://localhost:9870
- YARN ResourceManager: http://localhost:8088

## Step 3 — Prepare Airflow

```bash
bash bootstrap/02_start_airflow.sh
```

This script installs or refreshes the Mini BOP DAG inside the configured Airflow home and prints the commands required to start the Airflow webserver and scheduler.

Open two WSL terminals.

Terminal A:

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
airflow webserver --port 8080
```

Terminal B:

```bash
source ~/airflow-mini-bop/.venv/bin/activate
export AIRFLOW_HOME=~/airflow-mini-bop/airflow_home
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
airflow scheduler
```

Airflow UI:

```text
http://localhost:8080
```

## Step 4 — Start API and Dashboard

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash bootstrap/03_start_api.sh
```

API and dashboard:

- Swagger: http://localhost:8010/docs
- Dashboard: http://localhost:8010/dashboard

## Step 5 — Validate Platform

In a separate terminal:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_BASE=http://localhost:8010

bash bootstrap/04_validate_platform.sh
```

## Step 6 — Demo Readiness

```bash
bash bootstrap/05_demo_ready.sh
```

This script checks whether the platform is ready for a technical walkthrough.

## Stop Local Services

To stop Hadoop and YARN:

```bash
bash bootstrap/06_stop_platform.sh
```

Airflow and API processes started in terminals can be stopped with `Ctrl+C`.
