# Module 05 — Batch Processing Pipeline

> Understanding how a trade moves through the Mini BOP processing pipeline.

---

# Introduction

Mini BOP is intentionally designed around **batch processing**.

Rather than processing each transaction independently, trades are grouped into batches that can be validated, monitored, recovered and audited as a single execution unit.

---

# End-to-End Pipeline

```mermaid
graph LR
A[Source System]
--> B[STG_TRADE_RAW]
--> C[Validation]
--> D[Transformation]
--> E[TRADE]
--> F[TRADE_EVENT]
--> G[Observability]
--> H[Reconciliation]
--> I[Data Quality]
--> J[Audit & Lineage]
--> K[Export]
```

---

# Processing Stages

## 1. Ingestion

Incoming records are stored in the staging area.

Purpose:

- isolate external systems;
- preserve raw data;
- allow replay.

---

## 2. Validation

Business rules and master data references are verified.

Typical examples:

- mandatory fields;
- valid instrument;
- valid currency;
- positive quantity.

---

## 3. Transformation

Raw data is enriched and normalized before loading.

Examples:

- lookup identifiers;
- calculate derived values;
- normalize formats.

---

## 4. Load

Validated trades are persisted into the curated TRADE repository.

---

## 5. Event Generation

Business events record important milestones in the trade lifecycle.

---

## 6. Operational Governance

After loading, the pipeline evaluates:

- observability;
- reconciliation;
- data quality;
- audit lineage.

---

# Why Batch Processing?

Benefits include:

- repeatability;
- operational control;
- monitoring;
- recovery;
- auditing;
- scalability.

---

# Relationship with Oracle Packages

| Responsibility | Example Package |
|----------------|-----------------|
| Validation | Validation layer |
| Transformation | Transformation layer |
| Load | Load layer |
| Recovery | Recovery layer |
| Reconciliation | Reconciliation layer |
| Data Quality | Data Quality layer |
| Audit | Audit & Lineage |

---

# Engineering Notes

Batch processing provides a clear execution boundary.

Every batch can be:

- measured;
- replayed;
- audited;
- reconciled;
- compared.

This design is widely used in enterprise data platforms.

---

# Looking Ahead

In the Big Data Academy this same pipeline will be compared with:

- Apache Airflow DAGs
- Apache Spark jobs
- Hadoop ingestion
- dbt transformations

showing how the architectural responsibilities remain the same while implementation technologies evolve.

---

# Summary

After this module you should understand:

- Why Mini BOP uses batch processing.
- The stages of the pipeline.
- The role of governance after loading.
- How the pipeline prepares the project for future Big Data integration.

---

# Next Module

➡ **06_PERFORMANCE.md**
