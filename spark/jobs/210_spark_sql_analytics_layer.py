#!/usr/bin/env python3
# ============================================================
# MINI BOP - PHASE 21
# SPARK SQL ANALYTICS LAYER
# 210_spark_sql_analytics_layer.py
# ============================================================

import argparse
from pyspark.sql import SparkSession
from pyspark.sql.functions import (
    col,
    count,
    sum as spark_sum,
    avg,
    max as spark_max,
    min as spark_min,
    dense_rank,
    current_timestamp,
    lit,
)
from pyspark.sql.window import Window


def build_spark(app_name: str) -> SparkSession:
    return (
        SparkSession.builder
        .appName(app_name)
        .config("spark.sql.shuffle.partitions", "4")
        .config("spark.sql.sources.partitionOverwriteMode", "dynamic")
        .getOrCreate()
    )


def write_parquet(df, path: str) -> None:
    df.coalesce(1).write.mode("overwrite").parquet(path)


def main() -> None:
    parser = argparse.ArgumentParser(description="Mini BOP Phase 21 - Spark SQL Analytics Layer")
    parser.add_argument("--input-root", default="hdfs://localhost:9000/data/mini_bop/spark")
    parser.add_argument("--output-root", default="hdfs://localhost:9000/data/mini_bop/analytics")
    args = parser.parse_args()

    spark = build_spark("MiniBOP_Phase21_SparkSQLAnalyticsLayer")
    spark.sparkContext.setLogLevel("WARN")

    input_root = args.input_root.rstrip("/")
    output_root = args.output_root.rstrip("/")

    trade_curated_path = f"{input_root}/trade_curated"
    output_silver = f"{output_root}/silver_trade_enriched"
    output_gold_currency = f"{output_root}/gold_exposure_by_currency"
    output_gold_book = f"{output_root}/gold_exposure_by_book"
    output_gold_portfolio = f"{output_root}/gold_exposure_by_portfolio"
    output_gold_counterparty = f"{output_root}/gold_exposure_by_counterparty"
    output_gold_top_trades = f"{output_root}/gold_top_trades_by_amount"
    output_gold_dashboard = f"{output_root}/gold_dashboard_metrics"

    print("============================================================")
    print("MINI BOP - PHASE 21 - SPARK SQL ANALYTICS LAYER")
    print("============================================================")
    print(f"Input root : {input_root}")
    print(f"Output root: {output_root}")
    print(f"Reading    : {trade_curated_path}")

    trades = spark.read.parquet(trade_curated_path)

    # Register curated source as Spark SQL temp view.
    trades.createOrReplaceTempView("trade_curated")

    silver_trade_enriched = spark.sql(
        """
        SELECT
            trade_id,
            external_trade_id,
            source_system,
            trade_date,
            settlement_date,
            portfolio_id,
            book_id,
            counterparty_id,
            instrument_id,
            buy_sell,
            quantity,
            trade_price,
            trade_currency,
            notional_amount,
            market_value,
            amount_eur,
            trade_status,
            created_at,
            updated_at,
            CASE
                WHEN buy_sell = 'B' THEN amount_eur
                WHEN buy_sell = 'S' THEN -amount_eur
                ELSE amount_eur
            END AS signed_amount_eur,
            CASE
                WHEN amount_eur >= 10000000 THEN 'LARGE'
                WHEN amount_eur >= 1000000 THEN 'MEDIUM'
                ELSE 'SMALL'
            END AS exposure_bucket,
            DATEDIFF(settlement_date, trade_date) AS settlement_lag_days,
            current_timestamp() AS analytics_created_at
        FROM trade_curated
        WHERE trade_status = 'PROCESSED'
        """
    )
    silver_trade_enriched.createOrReplaceTempView("silver_trade_enriched")

    exposure_by_currency = spark.sql(
        """
        SELECT
            trade_currency,
            COUNT(*) AS trade_count,
            SUM(amount_eur) AS gross_amount_eur,
            SUM(signed_amount_eur) AS net_amount_eur,
            SUM(notional_amount) AS total_notional_amount,
            AVG(trade_price) AS avg_trade_price,
            MAX(amount_eur) AS max_trade_amount_eur,
            MIN(amount_eur) AS min_trade_amount_eur,
            current_timestamp() AS analytics_created_at
        FROM silver_trade_enriched
        GROUP BY trade_currency
        ORDER BY trade_currency
        """
    )

    exposure_by_book = spark.sql(
        """
        SELECT
            book_id,
            trade_currency,
            COUNT(*) AS trade_count,
            SUM(amount_eur) AS gross_amount_eur,
            SUM(signed_amount_eur) AS net_amount_eur,
            SUM(notional_amount) AS total_notional_amount,
            current_timestamp() AS analytics_created_at
        FROM silver_trade_enriched
        GROUP BY book_id, trade_currency
        ORDER BY book_id, trade_currency
        """
    )

    exposure_by_portfolio = spark.sql(
        """
        SELECT
            portfolio_id,
            trade_currency,
            COUNT(*) AS trade_count,
            SUM(amount_eur) AS gross_amount_eur,
            SUM(signed_amount_eur) AS net_amount_eur,
            SUM(notional_amount) AS total_notional_amount,
            current_timestamp() AS analytics_created_at
        FROM silver_trade_enriched
        GROUP BY portfolio_id, trade_currency
        ORDER BY portfolio_id, trade_currency
        """
    )

    exposure_by_counterparty = spark.sql(
        """
        SELECT
            counterparty_id,
            trade_currency,
            COUNT(*) AS trade_count,
            SUM(amount_eur) AS gross_amount_eur,
            SUM(signed_amount_eur) AS net_amount_eur,
            SUM(notional_amount) AS total_notional_amount,
            current_timestamp() AS analytics_created_at
        FROM silver_trade_enriched
        GROUP BY counterparty_id, trade_currency
        ORDER BY counterparty_id, trade_currency
        """
    )

    rank_window = Window.orderBy(col("amount_eur").desc())
    top_trades = (
        silver_trade_enriched
        .withColumn("amount_rank", dense_rank().over(rank_window))
        .select(
            "amount_rank",
            "trade_id",
            "external_trade_id",
            "portfolio_id",
            "book_id",
            "counterparty_id",
            "instrument_id",
            "buy_sell",
            "trade_currency",
            "amount_eur",
            "notional_amount",
            "exposure_bucket",
            "analytics_created_at",
        )
        .orderBy("amount_rank", "trade_id")
    )

    dashboard_metrics = spark.sql(
        """
        SELECT 'TOTAL_TRADES' AS metric_name, CAST(COUNT(*) AS DOUBLE) AS metric_value FROM silver_trade_enriched
        UNION ALL
        SELECT 'GROSS_AMOUNT_EUR', CAST(SUM(amount_eur) AS DOUBLE) FROM silver_trade_enriched
        UNION ALL
        SELECT 'NET_AMOUNT_EUR', CAST(SUM(signed_amount_eur) AS DOUBLE) FROM silver_trade_enriched
        UNION ALL
        SELECT 'TOTAL_NOTIONAL_AMOUNT', CAST(SUM(notional_amount) AS DOUBLE) FROM silver_trade_enriched
        UNION ALL
        SELECT 'LARGE_EXPOSURE_TRADES', CAST(SUM(CASE WHEN exposure_bucket = 'LARGE' THEN 1 ELSE 0 END) AS DOUBLE) FROM silver_trade_enriched
        """
    ).withColumn("analytics_created_at", current_timestamp())

    print("Writing silver_trade_enriched ->", output_silver)
    write_parquet(silver_trade_enriched, output_silver)

    print("Writing gold_exposure_by_currency ->", output_gold_currency)
    write_parquet(exposure_by_currency, output_gold_currency)

    print("Writing gold_exposure_by_book ->", output_gold_book)
    write_parquet(exposure_by_book, output_gold_book)

    print("Writing gold_exposure_by_portfolio ->", output_gold_portfolio)
    write_parquet(exposure_by_portfolio, output_gold_portfolio)

    print("Writing gold_exposure_by_counterparty ->", output_gold_counterparty)
    write_parquet(exposure_by_counterparty, output_gold_counterparty)

    print("Writing gold_top_trades_by_amount ->", output_gold_top_trades)
    write_parquet(top_trades, output_gold_top_trades)

    print("Writing gold_dashboard_metrics ->", output_gold_dashboard)
    write_parquet(dashboard_metrics, output_gold_dashboard)

    print("============================================================")
    print("SPARK PHASE 21 SUMMARY")
    print("============================================================")
    print(f"silver_count={silver_trade_enriched.count()}")
    print(f"currency_groups={exposure_by_currency.count()}")
    print(f"book_groups={exposure_by_book.count()}")
    print(f"portfolio_groups={exposure_by_portfolio.count()}")
    print(f"counterparty_groups={exposure_by_counterparty.count()}")
    print(f"top_trade_rows={top_trades.count()}")
    print(f"dashboard_metrics={dashboard_metrics.count()}")

    print("Dashboard metrics:")
    dashboard_metrics.orderBy("metric_name").show(truncate=False)

    print("Top trades:")
    top_trades.orderBy("amount_rank", "trade_id").show(truncate=False)

    print("Spark Phase 21 execution completed.")
    spark.stop()


if __name__ == "__main__":
    main()
