# FAQ

## What is Mini BOP?

Mini BOP is a reference implementation of an Enterprise Batch Orchestration Platform for financial data engineering workloads.

## What does the platform demonstrate?

It demonstrates the integration of Oracle, Hadoop, Hive, Spark, Airflow, monitoring, REST APIs and dashboards into a cohesive data processing architecture.

## Why Oracle?

Oracle is a common operational database in enterprise and financial environments. It provides a realistic source system for controlled batch extraction.

## Why Hadoop HDFS?

HDFS provides distributed storage for landing, curated and analytical datasets.

## Why Hive?

Hive provides SQL-based access over HDFS datasets and supports analytical inspection of exported data.

## Why Spark?

Spark provides distributed processing capabilities for transformation, aggregation and incremental processing.

## Why Airflow?

Airflow orchestrates the pipeline and provides operational visibility into workflow execution.

## Why FastAPI?

FastAPI exposes curated datasets and monitoring outputs through a clean REST interface with automatic OpenAPI documentation.

## Does the project require Docker?

No. The platform is designed for local execution in WSL using bootstrap scripts. Docker was intentionally removed from the final local packaging scope to keep the focus on transparent platform execution.

## How is the platform started?

The platform is started using scripts under `bootstrap/`.

## Where is the dashboard?

After starting the API, the dashboard is available at:

```text
http://localhost:8010/dashboard
```
