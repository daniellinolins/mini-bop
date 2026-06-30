# Mini BOP - Phase 5

## Trade Load Engine

This phase introduces the load layer of the Mini BOP trade processing pipeline.

## Package

- `PKG_TRADE_LOAD`

## Goal

Move validated trades from `STG_TRADE_RAW` into the core `TRADE` table.

## Flow

```text
STG_TRADE_RAW
    |
    | processing_status = VALIDATED
    v
PKG_TRADE_TRANSFORM
    |
    v
PKG_TRADE_LOAD
    |
    +--> TRADE
    |
    +--> STG_TRADE_RAW.PROCESSING_STATUS = PROCESSED
```

## Main Responsibilities

- Select staging records with `PROCESSING_STATUS = 'VALIDATED'`
- Transform each staging record using `PKG_TRADE_TRANSFORM`
- Insert new trades into `TRADE`
- Update existing trades when the same `EXTERNAL_TRADE_ID` and `SOURCE_SYSTEM` already exist
- Mark loaded staging records as `PROCESSED`
- Log load activity in `ETL_LOG`

## Idempotency

The package checks whether a trade already exists using:

```text
EXTERNAL_TRADE_ID + SOURCE_SYSTEM
```

If the trade exists, it updates the existing row instead of inserting a duplicate.

This is important for restartable batch processing.

## Execution

```sql
@scripts/run_phase5_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase5.sql
```

## Interview Talking Points

- Why should a load process be idempotent?
- Why use a staging status such as `VALIDATED` and `PROCESSED`?
- Why separate validation, transformation and load?
- What are the risks of row-by-row loading?
- How would this be optimized later with `BULK COLLECT` and `FORALL`?
- How would you design restartability in a production batch?
