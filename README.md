# Mini BOP

## Enterprise Batch Orchestration Platform

**Mini BOP (Mini Batch Orchestration Platform)** is a reference implementation of an Enterprise Data Engineering platform designed to demonstrate architectural decisions, engineering practices and operational capabilities commonly adopted in large-scale financial batch processing environments.

The platform integrates **Oracle Database, Hadoop HDFS, Hive, Apache Spark, Apache Airflow, FastAPI and an operational dashboard** into a cohesive end-to-end architecture focused on scalability, observability, restartability, incremental processing and operational readiness.

---

## Project Objectives

Mini BOP demonstrates the ability to design and implement a complete enterprise data processing platform with the following objectives:

- Ingest and process financial trade data from an Oracle source system.
- Export operational data to a Hadoop-based analytical platform.
- Provide external SQL access through Hive.
- Execute distributed transformation and aggregation with Apache Spark.
- Implement incremental processing, idempotency and data evolution patterns.
- Orchestrate the full pipeline with Apache Airflow.
- Provide operational monitoring, health checks and execution visibility.
- Expose curated datasets through REST APIs and an analytical dashboard.
- Package the local platform with bootstrap scripts for repeatable execution.
- Provide structured onboarding material through the Mini BOP Academy.

---

## Architecture Overview

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
Incremental & Analytics Layers
      |
      v
Airflow Orchestration
      |
      v
Monitoring & Health Reports
      |
      v
FastAPI REST Layer
      |
      v
Operational Dashboard
```

Mini BOP is organized as a layered data platform. Each layer has a clear responsibility and exposes outputs that are consumed by the next stage of the pipeline.

---

## Documentation Portal

Use this section as the main entry point to the project documentation.

### Getting Started

| Document | Description |
|---|---|
| [Quick Start](docs/reference/QUICK_START.md) | Local startup and validation procedure. |
| [Project Structure](docs/reference/PROJECT_STRUCTURE.md) | Repository organization and main folders. |
| [Troubleshooting](docs/reference/TROUBLESHOOTING.md) | Known issues and recovery procedures. |
| [FAQ](docs/reference/FAQ.md) | Common architectural and operational questions. |

### Architecture and Design

| Document | Description |
|---|---|
| [Architecture](docs/reference/ARCHITECTURE.md) | Platform architecture and layer responsibilities. |
| [Technologies](docs/reference/TECHNOLOGIES.md) | Technology stack and architectural roles. |
| [Domain Model](docs/DOMAIN_MODEL.md) | Business concepts and domain vocabulary. |
| [System Context](docs/SYSTEM_CONTEXT.md) | System boundaries and external context. |
| [Context Diagram](docs/CONTEXT_DIAGRAM.md) | High-level system context diagram. |
| [Component Diagram](docs/COMPONENT_DIAGRAM.md) | Internal architectural responsibility map. |
| [Sequence Diagrams](docs/SEQUENCE_DIAGRAMS.md) | Conceptual processing flows. |

### Planning and Decisions

| Document | Description |
|---|---|
| [Roadmap](docs/reference/ROADMAP.md) | Phase-by-phase project evolution. |
| [Architecture Decision Records](docs/decisions/README.md) | Architectural decision documentation. |
| [ADR Index](docs/decisions/ADR_INDEX.md) | Index of documented architecture decisions. |

---

## Mini BOP Academy

The **Mini BOP Academy** is a guided onboarding path for developers, data engineers and architects who want to understand the project progressively, from business concepts to code and architecture.

### Start here

| Resource | Description |
|---|---|
| [Academy Home](docs/academy/README.md) | Main entry point for the Academy. |
| [Learning Path](docs/academy/LEARNING_PATH.md) | Recommended study sequence. |
| [Glossary](docs/academy/GLOSSARY.md) | Business, engineering and Big Data terminology. |
| [Academy Style Guide](docs/academy/STYLE_GUIDE.md) | Editorial and visual standards. |
| [Academy Contributing Guide](docs/academy/CONTRIBUTING.md) | Contribution rules for Academy content. |

### Languages

| Language | Status | Entry point |
|---|---|---|
| 🇧🇷 Portuguese (PT-BR) | Available | [Mini BOP Academy PT-BR](docs/academy/pt-BR/README.md) |
| 🇺🇸 English (EN-US) | Structure available / translation in progress | [Mini BOP Academy EN-US](docs/academy/en-US/README.md) |
| 🇫🇷 French (FR-FR) | Structure available / translation in progress | [Mini BOP Academy FR-FR](docs/academy/fr-FR/README.md) |

### PT-BR Academy Modules

| Module | Topic |
|---:|---|
| 00 | [Welcome](docs/academy/pt-BR/academy/00_WELCOME.md) |
| 01 | [Financial Fundamentals](docs/academy/pt-BR/academy/01_FINANCIAL_FUNDAMENTALS.md) |
| 02 | [Financial Instruments](docs/academy/pt-BR/academy/02_FINANCIAL_INSTRUMENTS.md) |
| 03 | [Mini BOP Architecture](docs/academy/pt-BR/academy/03_MINI_BOP_ARCHITECTURE.md) |
| 04 | [Oracle Core](docs/academy/pt-BR/academy/04_ORACLE_CORE.md) |
| 05 | [Batch Processing Pipeline](docs/academy/pt-BR/academy/05_BATCH_PIPELINE.md) |
| 06 | [Performance](docs/academy/pt-BR/academy/06_PERFORMANCE.md) |
| 07 | [Recovery](docs/academy/pt-BR/academy/07_RECOVERY.md) |
| 08 | [Reconciliation](docs/academy/pt-BR/academy/08_RECONCILIATION.md) |
| 09 | [Data Quality](docs/academy/pt-BR/academy/09_DATA_QUALITY.md) |
| 10 | [Audit & Lineage](docs/academy/pt-BR/academy/10_AUDIT_LINEAGE.md) |
| 11 | [Metadata Engine](docs/academy/pt-BR/academy/11_METADATA_ENGINE.md) |
| 12 | [Big Data Overview](docs/academy/pt-BR/academy/12_BIG_DATA_OVERVIEW.md) |
| 13 | [Engineering Decisions](docs/academy/pt-BR/academy/13_ENGINEERING_DECISIONS.md) |
| 14 | [Technical Debt](docs/academy/pt-BR/academy/14_TECHNICAL_DEBT.md) |
| 15 | [Next Steps](docs/academy/pt-BR/academy/15_NEXT_STEPS.md) |

---

## Enterprise Capabilities

| Capability | Description |
|---|---|
| Configuration-driven execution | Pipeline behavior is controlled through configuration and reusable scripts. |
| Restartability | Processing steps include recovery and rerun patterns. |
| Audit and lineage | Pipeline execution, source-to-target movement and processing status are traceable. |
| Data quality | Quality checks and validation scripts are included across key phases. |
| Distributed storage | HDFS is used as the landing and analytical storage layer. |
| SQL access layer | Hive provides structured access over HDFS datasets. |
| Distributed processing | Spark performs transformation, aggregation and analytical computation. |
| Incremental processing | The platform demonstrates batch-based incremental processing and current-state derivation. |
| Orchestration | Airflow coordinates the full end-to-end process. |
| Observability | Monitoring scripts generate health reports and operational status. |
| REST integration | FastAPI exposes curated datasets to consuming applications. |
| Operational dashboard | A dashboard provides a lightweight view over platform outputs and metrics. |
| Bootstrap automation | Scripts simplify local environment validation and startup. |
| Onboarding documentation | The Mini BOP Academy provides structured knowledge transfer. |

---

## Technology Stack

| Layer | Technology | Architectural Role |
|---|---|---|
| Source System | Oracle Database | Trade data repository and transactional source. |
| Export Layer | PL/SQL, SQL, Bash | Controlled export from Oracle to analytical storage. |
| Storage Layer | Hadoop HDFS | Distributed landing and persistent analytical storage. |
| SQL Layer | Apache Hive | External table and query layer over HDFS data. |
| Processing Layer | Apache Spark / PySpark | Distributed transformation, aggregation and incremental processing. |
| Orchestration Layer | Apache Airflow | End-to-end workflow orchestration and scheduling. |
| Monitoring Layer | Python, Bash | Health checks, inventory and operational reports. |
| Integration Layer | FastAPI | RESTful access to curated analytical datasets. |
| Presentation Layer | HTML Dashboard, Swagger UI | Operational visibility and API exploration. |
| Automation Layer | Bash Bootstrap Scripts | Local platform startup, validation and demo readiness. |

---

## Repository Structure

```text
mini-bop/
├── airflow/       # Airflow DAGs and orchestration scripts
├── api/           # FastAPI application and dashboard
├── bootstrap/     # Local platform bootstrap scripts
├── config/        # Configuration files
├── data/          # Local export and sample data area
├── docs/          # Technical documentation, Academy and ADRs
├── hadoop/        # HDFS scripts and Hadoop-related assets
├── hive/          # Hive DDL and query layer scripts
├── monitoring/    # Health checks and operational reports
├── oracle/        # Oracle schema, packages, procedures and pipeline logic
├── scripts/       # Cross-platform operational scripts
├── spark/         # Spark jobs and analytics processing
├── README.md      # Executive repository overview
├── CHANGELOG.md   # Release history
└── CONTRIBUTING.md
```

More details are available in [Project Structure](docs/reference/PROJECT_STRUCTURE.md).

---

## Quick Start

The local platform is started through the bootstrap scripts.

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash bootstrap/00_check_environment.sh
bash bootstrap/01_start_hadoop.sh
bash bootstrap/02_start_airflow.sh
bash bootstrap/03_start_api.sh
```

In a second terminal:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_BASE=http://localhost:8010

bash bootstrap/04_validate_platform.sh
bash bootstrap/05_demo_ready.sh
```

Access points:

| Component | URL |
|---|---|
| Airflow UI | http://localhost:8080 |
| Swagger / OpenAPI | http://localhost:8010/docs |
| Operational Dashboard | http://localhost:8010/dashboard |
| Hadoop NameNode UI | http://localhost:9870 |
| YARN ResourceManager UI | http://localhost:8088 |

See [Quick Start](docs/reference/QUICK_START.md) for the complete startup procedure.

---

## REST API

The FastAPI layer exposes curated outputs from the analytical platform.

Main endpoints include:

| Endpoint | Purpose |
|---|---|
| `/health` | API health check. |
| `/pipeline/status` | Pipeline operational status. |
| `/metrics` | Monitoring checks and platform metrics. |
| `/trades/current` | Current-state trade records. |
| `/trades/top` | Top trades by amount. |
| `/exposure/currency` | Exposure by currency. |
| `/exposure/book` | Exposure by book. |
| `/incremental/checkpoint` | Incremental processing checkpoint. |
| `/dashboard` | Operational dashboard. |

Swagger documentation is available at `http://localhost:8010/docs`.

---

## Roadmap Summary

Mini BOP was implemented incrementally across a structured roadmap, from Oracle core processing to distributed analytics and operational readiness.

Major delivery areas include:

1. Oracle schema and batch control.
2. Trade load and transformation engine.
3. Performance, partitioning, data quality and restartability.
4. Oracle-to-Hadoop export.
5. Hive external table and query layer.
6. Spark processing and Spark SQL analytics.
7. Incremental processing and Delta Lake concepts.
8. Airflow orchestration.
9. Observability and monitoring.
10. REST API and operational dashboard.
11. Local platform packaging and bootstrap.
12. Professional documentation and demo readiness.
13. Academy and structured onboarding documentation.

See [Roadmap](docs/reference/ROADMAP.md) for the complete phase breakdown.

---

## Operational Model

Mini BOP is designed for local execution using WSL, with Hadoop, Hive, Spark, Airflow and the API running as local services. This keeps the platform transparent, easy to inspect and suitable for technical demonstration without hiding core engineering components behind opaque infrastructure.

The platform uses bootstrap scripts to standardize startup, validation and demo readiness.

---

## License

This project is released under the MIT License. See [LICENSE](LICENSE).
