# Mini BOP - Phase 12

## Reconciliation Engine

This phase introduces reconciliation controls for the Mini BOP pipeline.

## Main objects

- `PKG_RECONCILIATION`
- `VW_RECONCILIATION_METRICS`
- `VW_LATEST_RECONCILIATION_HEALTH`
- `VW_TRADE_RECONCILIATION_DETAIL`

## Purpose

The reconciliation engine compares the expected pipeline outcome with what was actually persisted in the core model.

It validates:

- staging total rows
- processed staging rows
- rejected staging rows
- loaded trade rows
- trade event rows
- missing trades
- missing events

## Flow

```text
Source pipeline batch
        |
        v
STG_TRADE_RAW
        |
        v
TRADE
        |
        v
TRADE_EVENT
        |
        v
PKG_RECONCILIATION
        |
        v
RECON_METRIC logs + reconciliation views
```

## Execution

```sql
@scripts/run_phase12_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase12.sql
```

## Interview talking points

- Why reconciliation is essential in financial pipelines
- Difference between technical success and reconciled success
- How to detect missing trades after ETL
- How to detect missing lifecycle events
- Why reconciliation should produce measurable metrics
- How reconciliation helps production support and auditability
