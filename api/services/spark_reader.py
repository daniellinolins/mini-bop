from __future__ import annotations

import os
from decimal import Decimal
from typing import Any, Dict, List

from pyspark.sql import SparkSession
from pyspark.sql import functions as F


def _clean_value(value: Any) -> Any:
    if isinstance(value, Decimal):
        return float(value)
    return value


def _rows_to_dicts(df, limit: int | None = None) -> List[Dict[str, Any]]:
    if limit is not None:
        df = df.limit(limit)
    return [{k: _clean_value(v) for k, v in row.asDict().items()} for row in df.collect()]


class MiniBopDataReader:
    def __init__(self) -> None:
        self.hdfs_base = os.environ.get("MINI_BOP_HDFS_BASE", "hdfs://localhost:9000/data/mini_bop")
        self._spark: SparkSession | None = None

    @property
    def spark(self) -> SparkSession:
        if self._spark is None:
            self._spark = (
                SparkSession.builder
                .appName("MiniBOP_Phase25_REST_API")
                .master(os.environ.get("MINI_BOP_SPARK_MASTER", "local[*]"))
                .config("spark.ui.showConsoleProgress", "false")
                .getOrCreate()
            )
            self._spark.sparkContext.setLogLevel("ERROR")
        return self._spark

    def _read(self, relative_path: str):
        return self.spark.read.parquet(f"{self.hdfs_base}/{relative_path}")

    def current_trades(self, limit: int = 50) -> List[Dict[str, Any]]:
        df = self._read("incremental/silver_current_trades")
        cols = [c for c in [
            "external_trade_id", "trade_currency", "buy_sell", "trade_status",
            "amount_eur", "notional_amount", "change_batch_id", "record_version", "is_current"
        ] if c in df.columns]
        return _rows_to_dicts(df.select(*cols).orderBy("external_trade_id"), limit)

    def top_trades(self, limit: int = 10) -> List[Dict[str, Any]]:
        df = self._read("analytics/gold_top_trades_by_amount")
        return _rows_to_dicts(df.orderBy(F.desc("amount_eur")), limit)

    def exposure_by_currency(self) -> List[Dict[str, Any]]:
        df = self._read("analytics/gold_exposure_by_currency")
        return _rows_to_dicts(df.orderBy("trade_currency"))

    def exposure_by_book(self) -> List[Dict[str, Any]]:
        df = self._read("analytics/gold_exposure_by_book")
        order_col = "total_amount_eur" if "total_amount_eur" in df.columns else df.columns[0]
        return _rows_to_dicts(df.orderBy(F.desc(order_col)))

    def incremental_checkpoint(self) -> List[Dict[str, Any]]:
        df = self._read("incremental/control_incremental_checkpoint")
        return _rows_to_dicts(df)
