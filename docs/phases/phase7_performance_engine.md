# Mini BOP - Phase 7

## Performance Engine

This phase introduces a bulk-oriented version of the trade load process.

## New Package

- `PKG_TRADE_LOAD_BULK`

## Goal

Compare the previous row-by-row load approach with a bulk processing approach using Oracle PL/SQL collections.

## Oracle Concepts Introduced

- Collections
- `BULK COLLECT`
- `FORALL`
- Batch size / LIMIT
- Reduced SQL to PL/SQL context switching
- Basic elapsed time measurement using `DBMS_UTILITY.GET_TIME`

## Flow

```text
STG_TRADE_RAW
      |
      v
PKG_TRADE_VALIDATE
      |
      v
VALIDATED rows
      |
      v
PKG_TRADE_LOAD_BULK
      |
      +--> BULK COLLECT staging rows
      +--> transform to PL/SQL collections
      +--> FORALL INSERT / UPDATE TRADE
      +--> FORALL UPDATE STG_TRADE_RAW to PROCESSED
      +--> generate TRADE_EVENT records
```

## Why This Matters

In Oracle PL/SQL, row-by-row processing can become slow because every SQL command executed inside a loop causes context switching between the PL/SQL engine and the SQL engine.

Using `BULK COLLECT` and `FORALL` reduces the number of context switches and is a common optimization technique in batch systems.

## Execution

```sql
@scripts/run_phase7_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase7.sql
```

## Expected Result

- 3 staging rows become `PROCESSED`
- 2 staging rows remain `REJECTED`
- 3 trades are loaded into `TRADE`
- 3 events are created in `TRADE_EVENT`
- The elapsed time is logged in `ETL_LOG`

## Interview Talking Points

- Why is row-by-row processing slower in PL/SQL?
- What is context switching?
- What is the difference between `BULK COLLECT` and `FORALL`?
- Why should bulk processing use a `LIMIT`?
- What are the risks of loading too much data into memory?
- When would you choose row-by-row despite the performance cost?
- How would you benchmark both approaches fairly?
