#!/usr/bin/env python3
import sys
from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def main():
    if len(sys.argv) != 2:
        print("Usage: 221_validate_incremental_outputs.py <output_root>", file=sys.stderr)
        sys.exit(2)
    output_root = sys.argv[1].rstrip("/")
    spark = SparkSession.builder.appName("MiniBOP_Phase22_IncrementalValidation").getOrCreate()
    spark.sparkContext.setLogLevel("WARN")

    datasets = {
        "bronze": spark.read.parquet(f"{output_root}/bronze_incremental_batches"),
        "current": spark.read.parquet(f"{output_root}/silver_current_trades"),
        "history": spark.read.parquet(f"{output_root}/silver_trade_history"),
        "change_log": spark.read.parquet(f"{output_root}/silver_trade_change_log"),
        "currency": spark.read.parquet(f"{output_root}/gold_incremental_currency_summary"),
        "metrics": spark.read.parquet(f"{output_root}/gold_incremental_metrics"),
        "jobs": spark.read.parquet(f"{output_root}/control_spark_job_history"),
        "checkpoint": spark.read.parquet(f"{output_root}/control_incremental_checkpoint"),
    }

    bronze_count = datasets["bronze"].count()
    current_count = datasets["current"].count()
    history_count = datasets["history"].count()
    change_log_count = datasets["change_log"].count()
    currency_count = datasets["currency"].count()
    metric_count = datasets["metrics"].count()
    job_count = datasets["jobs"].count()
    checkpoint_count = datasets["checkpoint"].count()
    duplicate_keys = datasets["current"].groupBy("external_trade_id").count().where(F.col("count") > 1).count()
    batch_ids = [r["change_batch_id"] for r in datasets["bronze"].select("change_batch_id").distinct().orderBy("change_batch_id").collect()]
    last_batch = datasets["checkpoint"].select("last_processed_batch_id").first()[0]

    print("=" * 60)
    print("SPARK PHASE 22 VALIDATION SUMMARY")
    print("=" * 60)
    print(f"bronze_change_rows={bronze_count}")
    print(f"current_trade_rows={current_count}")
    print(f"history_rows={history_count}")
    print(f"change_log_rows={change_log_count}")
    print(f"currency_rows={currency_count}")
    print(f"metric_rows={metric_count}")
    print(f"job_history_rows={job_count}")
    print(f"checkpoint_rows={checkpoint_count}")
    print(f"current_duplicate_business_keys={duplicate_keys}")
    print(f"batch_ids={batch_ids}")
    print(f"last_processed_batch_id={last_batch}")
    print("Current trades:")
    datasets["current"].select("external_trade_id", "change_batch_id", "change_operation", "record_version", "is_current", "trade_status", "amount_eur").orderBy("external_trade_id").show(truncate=False)
    print("Change log:")
    datasets["change_log"].orderBy("change_batch_id", "external_trade_id").show(truncate=False)
    print("Currency summary:")
    datasets["currency"].orderBy("trade_currency").show(truncate=False)

    expected = (
        bronze_count == 7 and
        current_count == 6 and
        history_count == 7 and
        change_log_count == 7 and
        currency_count == 2 and
        metric_count == 5 and
        job_count == 3 and
        checkpoint_count == 1 and
        duplicate_keys == 0 and
        batch_ids == [1, 2] and
        last_batch == 2
    )
    if expected:
        print("SPARK_PHASE22_STATUS=PASSED")
    else:
        print("SPARK_PHASE22_STATUS=FAILED")
        sys.exit(1)

    spark.stop()


if __name__ == "__main__":
    main()
