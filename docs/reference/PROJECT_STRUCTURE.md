# Project Structure

The repository is organized by platform layer.

```text
mini-bop/
├── airflow/
├── api/
├── bootstrap/
├── config/
├── data/
├── docs/
├── hadoop/
├── hive/
├── monitoring/
├── oracle/
├── scripts/
└── spark/
```

## Directory Overview

### `oracle/`

Oracle schemas, packages, procedures, SQL scripts and batch processing logic.

### `hadoop/`

HDFS directory creation, data upload and Hadoop integration scripts.

### `hive/`

Hive DDL and query layer assets.

### `spark/`

Spark jobs for processing, analytics and incremental data handling.

### `airflow/`

Airflow DAGs and installation scripts.

### `monitoring/`

Operational health checks and generated pipeline reports.

### `api/`

FastAPI application, services, templates, scripts and API validation.

### `bootstrap/`

Local startup, validation and demo-readiness scripts.

### `scripts/`

General platform scripts, including cleanup and operational helpers.

### `docs/`

Technical documentation, architecture, roadmap, troubleshooting and platform references.

### `data/`

Local export and sample data area.

### `config/`

Configuration files used by scripts and platform components.
