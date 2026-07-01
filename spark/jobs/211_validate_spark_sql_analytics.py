#!/usr/bin/env python3
# ============================================================
# MINI BOP - PHASE 21
# SPARK SQL ANALYTICS VALIDATION
# 211_validate_spark_sql_analytics.py
# ============================================================

import argparse
import sys
from pyspark.sql import SparkSession


def build_spark() -> SparkSession:
    return (
        SparkSession.builder
        .appName("MiniBOP_Phase21_AnalyticsValidation")
        .config("spark.sql.shuffle.partitions", "4")
        .getOrCreate()
    )


def main() -> None:
    parser = argparse.ArgumentParser(description="Validate Mini BOP Phase 21 Spark SQL analytics outputs")
    parser.add_argument("--analytics-root", default="hdfs://localhost:9000/data/mini_bop/analytics")
    args = parser.parse_args()

    spark = build_spark()
    spark.sparkContext.setLogLevel("WARN")

    root = args.analytics_root.rstrip("/")

    paths = {
        "silver": f"{root}/silver_trade_enriched",
        "currency": f"{root}/gold_exposure_by_currency",
        "book": f"{root}/gold_exposure_by_book",
        "portfolio": f"{root}/gold_exposure_by_portfolio",
        "counterparty": f"{root}/gold_exposure_by_counterparty",
        "top_trades": f"{root}/gold_top_trades_by_amount",
        "dashboard": f"{root}/gold_dashboard_metrics",
    }

    silver = spark.read.parquet(paths["silver"])
    currency = spark.read.parquet(paths["currency"])
    book = spark.read.parquet(paths["book"])
    portfolio = spark.read.parquet(paths["portfolio"])
    counterparty = spark.read.parquet(paths["counterparty"])
    top_trades = spark.read.parquet(paths["top_trades"])
    dashboard = spark.read.parquet(paths["dashboard"])

    metrics = {
        "silver_count": silver.count(),
        "currency_rows": currency.count(),
        "book_rows": book.count(),
        "portfolio_rows": portfolio.count(),
        "counterparty_rows": counterparty.count(),
        "top_trade_rows": top_trades.count(),
        "dashboard_metric_rows": dashboard.count(),
    }

    print("============================================================")
    print("SPARK PHASE 21 VALIDATION SUMMARY")
    print("============================================================")
    for key, value in metrics.items():
        print(f"{key}={value}")

    print("Currency exposure:")
    currency.orderBy("trade_currency").show(truncate=False)

    print("Dashboard metrics:")
    dashboard.orderBy("metric_name").show(truncate=False)

    expected = {
        "silver_count": 5,
        "currency_rows": 2,
        "dashboard_metric_rows": 5,
    }

    failures = []
    for key, expected_value in expected.items():
        if metrics[key] != expected_value:
            failures.append(f"{key}: expected={expected_value}, actual={metrics[key]}")

    if metrics["top_trade_rows"] < 5:
        failures.append(f"top_trade_rows: expected>=5, actual={metrics['top_trade_rows']}")

    if metrics["book_rows"] < 1 or metrics["portfolio_rows"] < 1 or metrics["counterparty_rows"] < 1:
        failures.append("book/portfolio/counterparty analytics should not be empty")

    if failures:
        print("SPARK_PHASE21_STATUS=FAILED")
        for failure in failures:
            print("FAILURE|" + failure)
        spark.stop()
        sys.exit(1)

    print("SPARK_PHASE21_STATUS=PASSED")
    spark.stop()


if __name__ == "__main__":
    main()
