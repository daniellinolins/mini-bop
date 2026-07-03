# Mini BOP - Phase 11

## Instrumentation & Observability

This phase adds operational observability to the Mini BOP Oracle pipeline.

## Components

- `PKG_OBSERVABILITY`
- `VW_BATCH_OBSERVABILITY`
- `VW_PIPELINE_METRICS`
- `VW_LATEST_PIPELINE_HEALTH`

## Main Ideas

The goal is to make pipeline execution easier to monitor, troubleshoot and explain.

The package uses:

- `DBMS_APPLICATION_INFO.SET_MODULE`
- `DBMS_APPLICATION_INFO.SET_ACTION`
- structured metric logs
- elapsed time measurements with `DBMS_UTILITY.GET_TIME`
- operational health views

## Instrumented Flow

```text
PKG_OBSERVABILITY
    |
    +-- START_BATCH
    +-- VALIDATE_TRADES
    +-- BULK_LOAD_TRADES
    +-- LOG_METRICS
    +-- END_BATCH
```

## Metrics Logged

- `attached_rows`
- `validation_elapsed_ms`
- `validated_rows`
- `rejected_rows`
- `bulk_load_elapsed_ms`
- `loaded_rows`
- `pipeline_elapsed_ms`

Metrics are stored in `ETL_LOG` using a simple structured format:

```text
METRIC|metric_name=value
```

## Execution

```sql
@scripts/run_phase11_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase11.sql
```

## Interview Talking Points

- Why instrument long-running PL/SQL jobs?
- What is the purpose of `DBMS_APPLICATION_INFO`?
- Difference between logs, metrics and health views
- Why elapsed time per step matters in production support
- How this helps root cause analysis in batch pipelines
