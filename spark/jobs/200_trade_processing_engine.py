#!/usr/bin/env python3
# ============================================================
# MINI BOP - PHASE 20
# SPARK PROCESSING ENGINE
# Reads Oracle-exported trade CSV from HDFS/Hive landing zone,
# cleans/types the data, and writes curated + analytical outputs.
# ============================================================

from pyspark.sql import SparkSession
from pyspark.sql import functions as F
from pyspark.sql.types import (
    StructType, StructField, StringType
)
import sys


def build_spark() -> SparkSession:
    return (
        SparkSession.builder
        .appName("MiniBOP_Phase20_TradeProcessingEngine")
        .config("spark.sql.session.timeZone", "UTC")
        .getOrCreate()
    )


def main() -> int:
    input_path = sys.argv[1] if len(sys.argv) > 1 else "hdfs://localhost:9000/data/mini_bop/hive/trade_core_csv"
    output_root = sys.argv[2] if len(sys.argv) > 2 else "hdfs://localhost:9000/data/mini_bop/spark"

    spark = build_spark()
    spark.sparkContext.setLogLevel("WARN")

    schema = StructType([
        StructField("trade_id_txt", StringType(), True),
        StructField("external_trade_id", StringType(), True),
        StructField("source_system", StringType(), True),
        StructField("trade_date_txt", StringType(), True),
        StructField("settlement_date_txt", StringType(), True),
        StructField("portfolio_id_txt", StringType(), True),
        StructField("book_id_txt", StringType(), True),
        StructField("counterparty_id_txt", StringType(), True),
        StructField("instrument_id_txt", StringType(), True),
        StructField("buy_sell", StringType(), True),
        StructField("quantity_txt", StringType(), True),
        StructField("trade_price_txt", StringType(), True),
        StructField("trade_currency", StringType(), True),
        StructField("notional_amount_txt", StringType(), True),
        StructField("market_value_txt", StringType(), True),
        StructField("amount_eur_txt", StringType(), True),
        StructField("trade_status", StringType(), True),
        StructField("created_at_txt", StringType(), True),
        StructField("updated_at_txt", StringType(), True),
    ])

    print("============================================================")
    print("MINI BOP - PHASE 20 - SPARK PROCESSING ENGINE")
    print("============================================================")
    print(f"Input path : {input_path}")
    print(f"Output root: {output_root}")

    raw_df = (
        spark.read
        .option("header", "false")
        .option("quote", '"')
        .option("escape", '"')
        .option("multiLine", "false")
        .schema(schema)
        .csv(input_path)
    )

    raw_count = raw_df.count()

    curated_df = (
        raw_df
        .where(F.col("trade_id_txt").rlike("^[0-9]+$"))
        .select(
            F.col("trade_id_txt").cast("long").alias("trade_id"),
            F.col("external_trade_id"),
            F.col("source_system"),
            F.to_date("trade_date_txt").alias("trade_date"),
            F.to_date("settlement_date_txt").alias("settlement_date"),
            F.col("portfolio_id_txt").cast("long").alias("portfolio_id"),
            F.col("book_id_txt").cast("long").alias("book_id"),
            F.col("counterparty_id_txt").cast("long").alias("counterparty_id"),
            F.col("instrument_id_txt").cast("long").alias("instrument_id"),
            F.col("buy_sell"),
            F.col("quantity_txt").cast("decimal(20,4)").alias("quantity"),
            F.col("trade_price_txt").cast("decimal(20,8)").alias("trade_price"),
            F.col("trade_currency"),
            F.col("notional_amount_txt").cast("decimal(20,4)").alias("notional_amount"),
            F.col("market_value_txt").cast("decimal(20,4)").alias("market_value"),
            F.col("amount_eur_txt").cast("decimal(20,4)").alias("amount_eur"),
            F.col("trade_status"),
            F.to_timestamp("created_at_txt").alias("created_at"),
            F.to_timestamp("updated_at_txt").alias("updated_at"),
            F.current_timestamp().alias("spark_processed_at"),
        )
    )

    curated_count = curated_df.count()

    summary_currency_df = (
        curated_df
        .groupBy("trade_currency")
        .agg(
            F.count("*").alias("trade_count"),
            F.sum("amount_eur").alias("total_amount_eur"),
            F.sum("notional_amount").alias("total_notional_amount"),
            F.avg("trade_price").alias("avg_trade_price"),
        )
        .orderBy("trade_currency")
    )

    summary_buy_sell_df = (
        curated_df
        .groupBy("buy_sell")
        .agg(
            F.count("*").alias("trade_count"),
            F.sum("amount_eur").alias("total_amount_eur"),
            F.sum("notional_amount").alias("total_notional_amount"),
        )
        .orderBy("buy_sell")
    )

    quality_df = spark.createDataFrame([
        ("RAW_ROW_COUNT_INCLUDING_HEADER", raw_count),
        ("CURATED_ROW_COUNT", curated_count),
        ("HEADER_ROWS_FILTERED", raw_count - curated_count),
    ], ["metric_name", "metric_value"])

    outputs = {
        "trade_curated": curated_df,
        "trade_summary_by_currency": summary_currency_df,
        "trade_summary_by_buy_sell": summary_buy_sell_df,
        "trade_quality_metrics": quality_df,
    }

    for name, df in outputs.items():
        path = f"{output_root}/{name}"
        print(f"Writing {name} -> {path}")
        df.coalesce(1).write.mode("overwrite").parquet(path)

    print("============================================================")
    print("SPARK PHASE 20 SUMMARY")
    print("============================================================")
    print(f"raw_count={raw_count}")
    print(f"curated_count={curated_count}")
    print(f"header_rows_filtered={raw_count - curated_count}")
    print("Currency summary:")
    summary_currency_df.show(truncate=False)
    print("Buy/Sell summary:")
    summary_buy_sell_df.show(truncate=False)

    spark.stop()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
