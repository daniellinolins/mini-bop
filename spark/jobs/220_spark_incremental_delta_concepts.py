#!/usr/bin/env python3
"""
MINI BOP - PHASE 22
Spark Incremental Processing & Delta Lake Concepts

This job intentionally uses Parquet only (no Delta dependency) to demonstrate:
- incremental batches
- watermark/checkpoint
- idempotent merge/upsert concepts
- current snapshot
- history table
- change log
- simple schema evolution

The implementation is driver-safe for the local WSL platform: small sample data is collected,
change sets are deterministically built on the driver, then written back as Spark DataFrames
with explicit schemas.
"""

import sys
from datetime import datetime
from decimal import Decimal
from typing import Any, Dict, List

from pyspark.sql import SparkSession
from pyspark.sql.types import (
    StructType, StructField, LongType, StringType, DecimalType,
    TimestampType, IntegerType
)
from pyspark.sql import functions as F


def now_ts() -> datetime:
    return datetime.now()


def dec(value: Any, default: str = "0") -> Decimal:
    if value is None:
        return Decimal(default)
    if isinstance(value, Decimal):
        return value
    return Decimal(str(value))


def safe_int(value: Any, default: int = 0) -> int:
    if value is None:
        return default
    return int(value)


def safe_str(value: Any, default: str = "") -> str:
    if value is None:
        return default
    return str(value)


TRADE_SCHEMA = StructType([
    StructField("trade_id", LongType(), False),
    StructField("external_trade_id", StringType(), False),
    StructField("source_system", StringType(), True),
    StructField("trade_date", StringType(), True),
    StructField("settlement_date", StringType(), True),
    StructField("portfolio_id", LongType(), True),
    StructField("book_id", LongType(), True),
    StructField("counterparty_id", LongType(), True),
    StructField("instrument_id", LongType(), True),
    StructField("buy_sell", StringType(), True),
    StructField("quantity", DecimalType(20, 4), True),
    StructField("trade_price", DecimalType(20, 8), True),
    StructField("trade_currency", StringType(), True),
    StructField("notional_amount", DecimalType(20, 4), True),
    StructField("market_value", DecimalType(20, 4), True),
    StructField("amount_eur", DecimalType(20, 4), True),
    StructField("trade_status", StringType(), True),
    StructField("change_batch_id", LongType(), False),
    StructField("change_operation", StringType(), False),
    StructField("record_version", IntegerType(), False),
    StructField("is_current", StringType(), False),
    StructField("valid_from", TimestampType(), False),
    StructField("valid_to", TimestampType(), True),
    StructField("schema_version", IntegerType(), False),
    StructField("source_file_name", StringType(), True),
    StructField("ingested_at", TimestampType(), False),
])

CHANGE_LOG_SCHEMA = StructType([
    StructField("change_batch_id", LongType(), False),
    StructField("external_trade_id", StringType(), False),
    StructField("change_operation", StringType(), False),
    StructField("old_amount_eur", DecimalType(20, 4), True),
    StructField("new_amount_eur", DecimalType(20, 4), True),
    StructField("old_trade_status", StringType(), True),
    StructField("new_trade_status", StringType(), True),
    StructField("processed_at", TimestampType(), False),
])

CHECKPOINT_SCHEMA = StructType([
    StructField("pipeline_name", StringType(), False),
    StructField("last_processed_batch_id", LongType(), False),
    StructField("last_processed_at", TimestampType(), False),
    StructField("checkpoint_status", StringType(), False),
])

JOB_HISTORY_SCHEMA = StructType([
    StructField("job_name", StringType(), False),
    StructField("run_id", StringType(), False),
    StructField("batch_id", LongType(), False),
    StructField("input_rows", LongType(), False),
    StructField("inserted_rows", LongType(), False),
    StructField("updated_rows", LongType(), False),
    StructField("current_rows", LongType(), False),
    StructField("status", StringType(), False),
    StructField("started_at", TimestampType(), False),
    StructField("ended_at", TimestampType(), False),
])

METRIC_SCHEMA = StructType([
    StructField("metric_name", StringType(), False),
    StructField("metric_value", DecimalType(20, 4), False),
    StructField("metric_created_at", TimestampType(), False),
])


def row_from_source(r: Dict[str, Any], batch_id: int, operation: str, version: int, is_current: str,
                    valid_from: datetime, valid_to: Any = None, schema_version: int = 1,
                    amount_override: Any = None, status_override: Any = None,
                    source_file_name: str = "phase20_trade_curated") -> Dict[str, Any]:
    amount_eur = dec(amount_override) if amount_override is not None else dec(r.get("amount_eur"))
    notional_amount = dec(r.get("notional_amount"))
    market_value = dec(r.get("market_value"))
    status = safe_str(status_override, safe_str(r.get("trade_status"), "PROCESSED"))
    return {
        "trade_id": safe_int(r.get("trade_id")),
        "external_trade_id": safe_str(r.get("external_trade_id")),
        "source_system": safe_str(r.get("source_system"), "MUREX_SIM"),
        "trade_date": str(r.get("trade_date")) if r.get("trade_date") is not None else None,
        "settlement_date": str(r.get("settlement_date")) if r.get("settlement_date") is not None else None,
        "portfolio_id": safe_int(r.get("portfolio_id")),
        "book_id": safe_int(r.get("book_id")),
        "counterparty_id": safe_int(r.get("counterparty_id")),
        "instrument_id": safe_int(r.get("instrument_id")),
        "buy_sell": safe_str(r.get("buy_sell")),
        "quantity": dec(r.get("quantity")),
        "trade_price": dec(r.get("trade_price")),
        "trade_currency": safe_str(r.get("trade_currency")),
        "notional_amount": notional_amount,
        "market_value": market_value,
        "amount_eur": amount_eur,
        "trade_status": status,
        "change_batch_id": int(batch_id),
        "change_operation": operation,
        "record_version": int(version),
        "is_current": is_current,
        "valid_from": valid_from,
        "valid_to": valid_to,
        "schema_version": int(schema_version),
        "source_file_name": source_file_name,
        "ingested_at": now_ts(),
    }


def main() -> None:
    if len(sys.argv) != 3:
        print("Usage: 220_spark_incremental_delta_concepts.py <input_curated_path> <output_root>", file=sys.stderr)
        sys.exit(2)

    input_path = sys.argv[1]
    output_root = sys.argv[2].rstrip("/")

    spark = (
        SparkSession.builder
        .appName("MiniBOP_Phase22_IncrementalDeltaConcepts")
        .config("spark.sql.shuffle.partitions", "1")
        .config("spark.sql.debug.maxToStringFields", "200")
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")

    print("=" * 60)
    print("MINI BOP - PHASE 22 - SPARK INCREMENTAL / DELTA CONCEPTS")
    print("=" * 60)
    print(f"Input curated path: {input_path}")
    print(f"Output root       : {output_root}")

    started_at = now_ts()

    print("Reading Phase 20 curated trades...")
    source_df = spark.read.parquet(input_path)
    source_rows = [r.asDict(recursive=True) for r in source_df.orderBy("trade_id").collect()]
    print(f"Source rows loaded: {len(source_rows)}")

    if not source_rows:
        raise RuntimeError("No source rows found in Phase 20 curated dataset")

    by_ext = {r["external_trade_id"]: r for r in source_rows}
    t1 = now_ts()
    t2 = now_ts()

    print("Building deterministic incremental batches...")

    # Batch 1: initial load with 5 trades.
    batch1_current = [row_from_source(r, 1, "INSERT", 1, "Y", t1, schema_version=1) for r in source_rows]

    # Batch 2: one update and one insert to simulate MERGE/UPSERT.
    updated_source = by_ext.get("TRD-000002", source_rows[1])
    new_trade_base = dict(source_rows[0])
    new_trade_base.update({
        "trade_id": 6,
        "external_trade_id": "TRD-000006",
        "portfolio_id": 4,
        "book_id": 4,
        "counterparty_id": 4,
        "instrument_id": 2,
        "buy_sell": "B",
        "quantity": Decimal("750000.0000"),
        "trade_price": Decimal("101.25000000"),
        "trade_currency": "EUR",
        "notional_amount": Decimal("75937500.0000"),
        "market_value": Decimal("75937500.0000"),
        "amount_eur": Decimal("75937500.0000"),
        "trade_status": "PROCESSED",
    })

    batch2_update_old = row_from_source(updated_source, 2, "UPDATE_OLD", 1, "N", t1, t2, schema_version=1)
    batch2_update_new = row_from_source(
        updated_source,
        2,
        "UPDATE_NEW",
        2,
        "Y",
        t2,
        None,
        schema_version=2,
        amount_override=Decimal("510000.0000"),
        status_override="AMENDED",
        source_file_name="phase22_incremental_batch_2",
    )
    batch2_insert = row_from_source(
        new_trade_base,
        2,
        "INSERT",
        1,
        "Y",
        t2,
        None,
        schema_version=2,
        source_file_name="phase22_incremental_batch_2",
    )

    # Bronze represents all arriving changes.
    bronze_rows = batch1_current + [batch2_update_new, batch2_insert]

    # History represents SCD2-style full timeline: initial current records, old closed version, new version, new insert.
    history_rows = []
    for row in batch1_current:
        if row["external_trade_id"] == batch2_update_old["external_trade_id"]:
            history_rows.append(batch2_update_old)
        else:
            history_rows.append(row)
    history_rows.extend([batch2_update_new, batch2_insert])

    # Current snapshot represents idempotent merge result: 6 business keys, latest versions only.
    current_by_key: Dict[str, Dict[str, Any]] = {}
    for row in history_rows:
        if row["is_current"] == "Y":
            current_by_key[row["external_trade_id"]] = row
    current_rows = list(current_by_key.values())

    change_rows = []
    for row in batch1_current:
        change_rows.append({
            "change_batch_id": 1,
            "external_trade_id": row["external_trade_id"],
            "change_operation": "INSERT",
            "old_amount_eur": None,
            "new_amount_eur": row["amount_eur"],
            "old_trade_status": None,
            "new_trade_status": row["trade_status"],
            "processed_at": t1,
        })
    change_rows.append({
        "change_batch_id": 2,
        "external_trade_id": batch2_update_new["external_trade_id"],
        "change_operation": "UPDATE",
        "old_amount_eur": batch2_update_old["amount_eur"],
        "new_amount_eur": batch2_update_new["amount_eur"],
        "old_trade_status": "PROCESSED",
        "new_trade_status": "AMENDED",
        "processed_at": t2,
    })
    change_rows.append({
        "change_batch_id": 2,
        "external_trade_id": batch2_insert["external_trade_id"],
        "change_operation": "INSERT",
        "old_amount_eur": None,
        "new_amount_eur": batch2_insert["amount_eur"],
        "old_trade_status": None,
        "new_trade_status": batch2_insert["trade_status"],
        "processed_at": t2,
    })

    def write_df(rows: List[Dict[str, Any]], schema: StructType, name: str) -> None:
        path = f"{output_root}/{name}"
        print(f"Writing {name} -> {path}")
        df = spark.createDataFrame(rows, schema=schema)
        df.coalesce(1).write.mode("overwrite").parquet(path)

    write_df(bronze_rows, TRADE_SCHEMA, "bronze_incremental_batches")
    write_df(current_rows, TRADE_SCHEMA, "silver_current_trades")
    write_df(history_rows, TRADE_SCHEMA, "silver_trade_history")
    write_df(change_rows, CHANGE_LOG_SCHEMA, "silver_trade_change_log")

    current_df = spark.read.parquet(f"{output_root}/silver_current_trades")
    currency_df = (
        current_df.groupBy("trade_currency")
        .agg(
            F.count("*").alias("trade_count"),
            F.sum("amount_eur").alias("total_amount_eur"),
            F.sum("notional_amount").alias("total_notional_amount"),
            F.max("change_batch_id").alias("max_change_batch_id"),
        )
        .orderBy("trade_currency")
    )
    print(f"Writing gold_incremental_currency_summary -> {output_root}/gold_incremental_currency_summary")
    currency_df.coalesce(1).write.mode("overwrite").parquet(f"{output_root}/gold_incremental_currency_summary")

    metric_rows = [
        {"metric_name": "BRONZE_CHANGE_ROWS", "metric_value": Decimal(str(len(bronze_rows))), "metric_created_at": now_ts()},
        {"metric_name": "CURRENT_TRADE_ROWS", "metric_value": Decimal(str(len(current_rows))), "metric_created_at": now_ts()},
        {"metric_name": "HISTORY_ROWS", "metric_value": Decimal(str(len(history_rows))), "metric_created_at": now_ts()},
        {"metric_name": "CHANGE_LOG_ROWS", "metric_value": Decimal(str(len(change_rows))), "metric_created_at": now_ts()},
        {"metric_name": "LAST_PROCESSED_BATCH_ID", "metric_value": Decimal("2"), "metric_created_at": now_ts()},
    ]
    write_df(metric_rows, METRIC_SCHEMA, "gold_incremental_metrics")

    checkpoint_rows = [{
        "pipeline_name": "MINI_BOP_SPARK_INCREMENTAL",
        "last_processed_batch_id": 2,
        "last_processed_at": now_ts(),
        "checkpoint_status": "READY",
    }]
    write_df(checkpoint_rows, CHECKPOINT_SCHEMA, "control_incremental_checkpoint")

    ended_at = now_ts()
    job_history_rows = [
        {
            "job_name": "phase22_initial_load",
            "run_id": "phase22_batch_1",
            "batch_id": 1,
            "input_rows": len(source_rows),
            "inserted_rows": len(batch1_current),
            "updated_rows": 0,
            "current_rows": len(batch1_current),
            "status": "SUCCESS",
            "started_at": started_at,
            "ended_at": ended_at,
        },
        {
            "job_name": "phase22_incremental_merge",
            "run_id": "phase22_batch_2",
            "batch_id": 2,
            "input_rows": 2,
            "inserted_rows": 1,
            "updated_rows": 1,
            "current_rows": len(current_rows),
            "status": "SUCCESS",
            "started_at": started_at,
            "ended_at": ended_at,
        },
        {
            "job_name": "phase22_idempotency_check",
            "run_id": "phase22_idempotency",
            "batch_id": 2,
            "input_rows": 2,
            "inserted_rows": 0,
            "updated_rows": 0,
            "current_rows": len(current_rows),
            "status": "SUCCESS",
            "started_at": started_at,
            "ended_at": ended_at,
        },
    ]
    write_df(job_history_rows, JOB_HISTORY_SCHEMA, "control_spark_job_history")

    duplicate_keys = current_df.groupBy("external_trade_id").count().where(F.col("count") > 1).count()
    batch_ids = [r["change_batch_id"] for r in spark.read.parquet(f"{output_root}/bronze_incremental_batches").select("change_batch_id").distinct().orderBy("change_batch_id").collect()]

    print("=" * 60)
    print("SPARK PHASE 22 SUMMARY")
    print("=" * 60)
    print(f"bronze_change_rows={len(bronze_rows)}")
    print(f"current_trade_rows={len(current_rows)}")
    print(f"history_rows={len(history_rows)}")
    print(f"change_log_rows={len(change_rows)}")
    print(f"currency_rows={currency_df.count()}")
    print(f"metric_rows={len(metric_rows)}")
    print(f"job_history_rows={len(job_history_rows)}")
    print(f"checkpoint_rows={len(checkpoint_rows)}")
    print(f"current_duplicate_business_keys={duplicate_keys}")
    print(f"batch_ids={batch_ids}")
    print("last_processed_batch_id=2")
    print("Spark Phase 22 execution completed.")

    spark.stop()


if __name__ == "__main__":
    main()
