# Mini BOP - Phase 22 - Spark Incremental Processing & Delta Lake Concepts

## Goal

Phase 22 extends the Mini BOP data lake with incremental processing concepts normally provided by Delta Lake / Lakehouse platforms, but implemented using Spark + Parquet so no extra dependency is required.

The phase demonstrates:

- incremental batches;
- deterministic reprocessing;
- idempotency;
- MERGE-like upsert by business key;
- SCD Type 2 history;
- checkpoint / watermark;
- job history;
- change log;
- schema evolution;
- Gold metrics after incremental merge.

## Input

The phase reads the curated Parquet dataset produced by Phase 20:

```text
hdfs://localhost:9000/data/mini_bop/spark/trade_curated
```

## Output

The phase writes the incremental lakehouse simulation into:

```text
hdfs://localhost:9000/data/mini_bop/incremental
```

Datasets:

```text
bronze_incremental_batches
silver_current_trades
silver_trade_history_scd2
delta_concept_change_log
job_control_checkpoint
spark_job_history
gold_current_exposure_by_currency
gold_incremental_dashboard_metrics
```

## Incremental Scenario

The job creates a deterministic two-batch scenario:

### Batch 1

Initial snapshot from Phase 20 curated trades.

Expected rows:

```text
5 initial trades
```

### Batch 2

Simulated CDC batch:

```text
1 UPDATE: TRD-000002
1 INSERT: TRD-000006
```

Expected incremental rows:

```text
7 bronze change rows
6 current trades
7 SCD2 history rows
```

## Delta Lake Concepts Simulated

### MERGE / UPSERT

Spark keeps only the latest record per `external_trade_id` in `silver_current_trades`.

Equivalent conceptual operation:

```sql
MERGE INTO silver_current_trades target
USING bronze_incremental_batches source
ON target.external_trade_id = source.external_trade_id
WHEN MATCHED THEN UPDATE
WHEN NOT MATCHED THEN INSERT;
```

### Idempotency

The phase overwrites deterministic outputs. Running the same job multiple times does not duplicate current trades or history rows.

### Watermark

`job_control_checkpoint` stores:

```text
last_processed_batch_id
last_watermark_ts
processed_change_rows
checkpoint_strategy
```

### SCD Type 2

`silver_trade_history_scd2` stores all historical versions and marks only the latest version as current.

### Schema Evolution

Batch 2 introduces `risk_segment`, demonstrating how new attributes can appear in later batches and still be handled in the curated outputs.

## Run

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

bash hadoop/spark/220_run_spark_phase22.sh
```

## Validate

```bash
bash hadoop/spark/221_validate_spark_phase22.sh
```

Expected:

```text
bronze_change_rows=7
current_trade_rows=6
history_rows=7
change_log_rows=7
currency_rows=2
metric_rows=5
job_history_rows=3
checkpoint_rows=1
current_duplicate_business_keys=0
batch_ids=[1, 2]
last_processed_batch_id=2
SPARK_PHASE22_STATUS=PASSED
```

## Interview Talking Points

This phase is useful to discuss:

- why full reloads are expensive;
- how incremental batch processing reduces workload;
- how a watermark avoids reprocessing old data;
- why idempotency matters in production pipelines;
- how SCD Type 2 preserves history;
- how Delta Lake `MERGE` can be conceptually simulated with Spark + Parquet;
- why schema evolution matters in financial data platforms;
- why job history and checkpoints are essential for restartability.
