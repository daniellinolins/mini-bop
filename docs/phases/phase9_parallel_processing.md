# Mini BOP - Phase 9

## Parallel Processing Engine

This phase introduces a parallel-style processing layer for the Mini BOP Oracle pipeline.

## Package

- `PKG_TRADE_PARALLEL`

## Main Goal

The goal is to simulate how a large financial batch can be split into chunks and processed by independent workers.

## Implemented Concepts

- Chunk processing
- Parallel-level parameter
- Chunk logs
- Batch orchestration
- Comparison foundation against sequential bulk processing
- `DBMS_UTILITY.GET_TIME` performance measurement

## Important Note

This reference implementation uses chunked execution inside a single Oracle session. It prepares the architecture for true database parallelism, but it does not yet use `DBMS_PARALLEL_EXECUTE` workers.

The next enhancement can evolve this phase into real Oracle parallel execution.

## Flow

```text
STG_TRADE_RAW
      |
      v
PKG_TRADE_VALIDATE
      |
      v
VALIDATED records
      |
      v
Chunk 1 / Chunk 2 / Chunk N
      |
      v
PKG_TRADE_PARALLEL.LOAD_CHUNK
      |
      v
TRADE + TRADE_EVENT
```

## Execution

```sql
@scripts/run_phase9_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase9.sql
```

## Interview Talking Points

- Why split a large batch into chunks?
- What is the difference between bulk processing and parallel processing?
- How would you avoid duplicated processing between workers?
- How would you implement restartability per chunk?
- When would `DBMS_PARALLEL_EXECUTE` be appropriate?
- What are the risks of parallel DML in financial systems?
