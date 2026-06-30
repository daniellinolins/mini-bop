# Mini BOP - Phase 13

## Recovery / Restartability Engine

This phase introduces restartability into the Mini BOP Oracle pipeline.

## Package

- `PKG_RECOVERY`

## Views

- `VW_RECOVERY_CANDIDATES`
- `VW_RECOVERY_BATCH_SUMMARY`
- `VW_LATEST_RECOVERY_ACTIVITY`

## Main Goals

The recovery engine allows the platform to reprocess only failed or rejected staging rows without replaying the entire pipeline unnecessarily.

## Supported Operations

### Restart rejected trades

```sql
BEGIN
    DBMS_OUTPUT.PUT_LINE(pkg_recovery.restart_rejected_trades);
END;
/
```

This operation:

1. creates a new recovery batch;
2. attaches rejected rows to that batch;
3. resets their status to `NEW`;
4. runs validation;
5. loads valid corrected rows;
6. generates events;
7. finalizes the batch.

### Replay a source batch

```sql
BEGIN
    DBMS_OUTPUT.PUT_LINE(pkg_recovery.replay_batch(14));
END;
/
```

This replays all staging rows from a given source batch into a new recovery batch.

## Why this matters

In real banking batch systems, restartability is critical. A process should not require full reloads for every operational issue. The system must support controlled recovery, idempotent loading and operational auditability.

## Interview talking points

- Why is restartability critical in batch pipelines?
- How do you avoid duplicate trades during reprocessing?
- Why create a new batch instead of mutating the old one?
- What is the difference between replay and restart?
- How does idempotent load support recovery?
- How would you handle partial failure in a parallel job?
