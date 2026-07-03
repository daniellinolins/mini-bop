# Mini BOP - Phase 14

## Data Quality Framework

This phase introduces a metadata-driven Data Quality Framework for the Mini BOP platform.

## New Objects

### Tables

- `DQ_RULE`
- `DQ_RESULT`

### Package

- `PKG_DATA_QUALITY`

### Views

- `VW_DQ_RULE_RESULTS`
- `VW_DQ_BATCH_SUMMARY`
- `VW_LATEST_DQ_HEALTH`
- `VW_DQ_FAILED_RULES`

## Implemented Data Quality Rules

- `STG_REQUIRED_EXTERNAL_ID`
- `STG_VALID_PROCESSING_STATUS`
- `REJECTED_HAS_ERROR_DETAIL`
- `PROCESSED_HAS_TRADE`
- `TRADE_POSITIVE_NOTIONAL`
- `TRADE_HAS_EVENT`

## Flow

```text
Trade Pipeline
      |
      v
STG_TRADE_RAW / TRADE / TRADE_EVENT
      |
      v
PKG_DATA_QUALITY
      |
      v
DQ_RESULT
      |
      v
DQ Views / Health Status
```

## Why this matters

In real banking platforms, processing success is not enough. A pipeline also needs to prove that data is complete, valid, accurate, consistent and traceable.

This phase adds rule-level scoring and a batch-level health view.

## Execution

```sql
@scripts/run_phase14_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase14.sql
```

## Interview Talking Points

- Why separate validation errors from data quality rules?
- What is the difference between technical validation and data quality?
- Why store rules and results in metadata tables?
- How would this scale to hundreds of rules?
- How would you integrate DQ metrics with dashboards or monitoring tools?
