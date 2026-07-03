# Architecture

Mini BOP implements a layered Enterprise Data Engineering architecture for financial batch processing.

## Logical Architecture

```text
Oracle Database
      |
      v
Oracle Export Engine
      |
      v
HDFS Landing Zone
      |
      v
Hive External Table Layer
      |
      v
Spark Processing Engine
      |
      v
Incremental Processing Layer
      |
      v
Analytics Layer
      |
      v
Airflow Orchestration
      |
      v
Monitoring and Observability
      |
      v
FastAPI Integration Layer
      |
      v
Operational Dashboard
```

## Layer Responsibilities

### Source Layer

Oracle Database acts as the operational source system for trade, portfolio, counterparty, instrument and batch control data.

### Export Layer

The export layer extracts controlled datasets from Oracle and prepares files for distributed analytical processing.

### Storage Layer

Hadoop HDFS stores landing, Hive, Spark, incremental and analytics datasets.

### SQL Access Layer

Hive provides external table definitions over HDFS data and enables SQL-based inspection of exported datasets.

### Processing Layer

Spark transforms, validates and aggregates trade data. It produces curated datasets, summaries, quality metrics and analytical outputs.

### Incremental Layer

The incremental layer implements batch-based processing, current-state derivation, change logs, history and checkpoints.

### Orchestration Layer

Airflow coordinates the end-to-end process and provides workflow-level operational visibility.

### Monitoring Layer

Monitoring scripts inspect HDFS, Spark, incremental outputs, Airflow status and business-level checks. Results are published as JSON and Markdown reports.

### Integration Layer

FastAPI exposes curated datasets and monitoring information through REST endpoints and Swagger documentation.

### Presentation Layer

The dashboard provides a compact operational view over pipeline status, trade exposure and platform metrics.

## Data Flow

1. Oracle stores operational trade data.
2. Export scripts create controlled CSV exports and manifests.
3. Files are uploaded to HDFS landing zones.
4. Hive creates external access over CSV datasets.
5. Spark reads HDFS inputs and writes curated Parquet outputs.
6. Incremental processing produces current, history, change log and checkpoint datasets.
7. Analytics jobs create aggregated metrics.
8. Monitoring consolidates platform health.
9. FastAPI exposes results to applications and the dashboard.

## Operational Principles

Mini BOP emphasizes:

- Clear layer ownership.
- Reusable scripts.
- Explicit validation.
- Traceable data movement.
- Controlled restartability.
- Operational health reporting.
- API-based integration.
