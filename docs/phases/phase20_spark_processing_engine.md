# Mini BOP - Phase 20 - Spark Processing Engine

## Goal

Phase 20 adds a Spark processing layer after Oracle -> HDFS -> Hive.

The pipeline reads the CSV exported from Oracle and staged in HDFS, removes the header row, casts fields into proper data types, and writes curated analytical outputs in Parquet.

## Flow

```text
Oracle TRADE
  -> CSV/Manifest
  -> HDFS landing zone
  -> Hive external table
  -> Spark DataFrame processing
  -> Parquet analytical outputs
```

## Inputs

```text
/data/mini_bop/hive/trade_core_csv
```

## Outputs

```text
/data/mini_bop/spark/trade_curated
/data/mini_bop/spark/trade_summary_by_currency
/data/mini_bop/spark/trade_summary_by_buy_sell
/data/mini_bop/spark/trade_quality_metrics
```

## Run

```bash
bash hadoop/spark/200_run_spark_phase20.sh
```

## Validate

```bash
bash hadoop/spark/201_validate_spark_phase20.sh
```

## Expected validation

```text
CURATED_ROW_COUNT = 5
HEADER_ROWS_FILTERED = 1
HIVE_PHASE20_STATUS=PASSED
```

## Interview talking point

This phase demonstrates the typical transition from operational processing in Oracle to distributed analytical processing in Spark. The Spark job materializes a clean curated dataset and aggregate datasets suitable for downstream reporting, reconciliation, risk analytics, or further machine learning pipelines.
