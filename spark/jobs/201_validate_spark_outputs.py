#!/usr/bin/env python3
"""
MINI BOP - PHASE 20
Spark output validation job.

This script must be executed with spark-submit, not plain python3,
because PySpark is provided by the Spark runtime.
"""

import argparse
import sys
from pyspark.sql import SparkSession
from pyspark.sql.functions import col


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output-root", required=True)
    args = parser.parse_args()

    spark = (
        SparkSession.builder
        .appName("MiniBOP_Phase20_OutputValidation")
        .getOrCreate()
    )

    output_root = args.output_root.rstrip("/")

    curated = spark.read.parquet(f"{output_root}/trade_curated")
    by_currency = spark.read.parquet(f"{output_root}/trade_summary_by_currency")
    by_buy_sell = spark.read.parquet(f"{output_root}/trade_summary_by_buy_sell")
    quality = spark.read.parquet(f"{output_root}/trade_quality_metrics")

    curated_count = curated.count()
    currency_count = by_currency.count()
    buy_sell_count = by_buy_sell.count()
    quality_count = quality.count()

    print("============================================================")
    print("SPARK PHASE 20 VALIDATION SUMMARY")
    print("============================================================")
    print(f"curated_count={curated_count}")
    print(f"currency_summary_rows={currency_count}")
    print(f"buy_sell_summary_rows={buy_sell_count}")
    print(f"quality_metric_rows={quality_count}")

    print("Curated trades:")
    curated.select(
        "trade_id",
        "external_trade_id",
        "trade_currency",
        "buy_sell",
        "amount_eur",
        "trade_status",
    ).orderBy("trade_id").show(truncate=False)

    print("Summary by currency:")
    by_currency.orderBy("trade_currency").show(truncate=False)

    print("Summary by buy/sell:")
    by_buy_sell.orderBy("buy_sell").show(truncate=False)

    print("Quality metrics:")
    quality.orderBy("metric_name").show(truncate=False)

    if curated_count != 5:
        print(f"ERROR: expected curated_count=5, got {curated_count}", file=sys.stderr)
        return 1

    processed_count = curated.filter(col("trade_status") == "PROCESSED").count()
    if processed_count != 5:
        print(f"ERROR: expected 5 PROCESSED trades, got {processed_count}", file=sys.stderr)
        return 1

    if currency_count != 2:
        print(f"ERROR: expected 2 currency summary rows, got {currency_count}", file=sys.stderr)
        return 1

    if buy_sell_count != 2:
        print(f"ERROR: expected 2 buy/sell summary rows, got {buy_sell_count}", file=sys.stderr)
        return 1

    print("SPARK_PHASE20_STATUS=PASSED")
    spark.stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
