# Mini BOP - Phase 8

## Batch Scheduler

This phase introduces automatic batch orchestration using Oracle `DBMS_SCHEDULER`.

## New Package

- `PKG_BATCH_SCHEDULER`

## Main Responsibilities

- Create the daily Mini BOP trade pipeline job.
- Drop/recreate the scheduler job safely.
- Execute the scheduled job immediately for testing.
- Run the full trade pipeline:
  - Create ETL batch.
  - Assign new staging rows to the batch.
  - Validate trades.
  - Load validated trades using the bulk loader.
  - Generate trade events.
  - Write ETL logs.
  - End the batch with status.

## Scheduler Job

Default job name:

```text
MINI_BOP_DAILY_TRADE_PIPELINE
```

Default schedule:

```text
FREQ=DAILY;BYHOUR=2;BYMINUTE=0;BYSECOND=0
```

## Execution

```sql
@scripts/run_phase8_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase8.sql
```

## Pipeline

```text
DBMS_SCHEDULER
      |
      v
PKG_BATCH_SCHEDULER.RUN_TRADE_PIPELINE
      |
      v
PKG_LOG.START_BATCH
      |
      v
PKG_TRADE_VALIDATE
      |
      v
PKG_TRADE_LOAD_BULK
      |
      v
PKG_TRADE_EVENT
      |
      v
PKG_LOG.END_BATCH
```

## Interview Talking Points

- Why use `DBMS_SCHEDULER` instead of manual execution?
- What is the difference between orchestration and processing logic?
- Why should scheduler code call a pipeline package instead of embedding all logic in the job action?
- How would you monitor scheduled jobs in production?
- How would you handle failed jobs and restarts?
- Why is idempotency important in scheduled ETL jobs?

## Useful Queries

```sql
SELECT job_name, enabled, state, repeat_interval
FROM user_scheduler_jobs
WHERE job_name = 'MINI_BOP_DAILY_TRADE_PIPELINE';
```

```sql
SELECT job_name, status, actual_start_date, run_duration, errors
FROM user_scheduler_job_run_details
WHERE job_name = 'MINI_BOP_DAILY_TRADE_PIPELINE'
ORDER BY log_date DESC;
```
