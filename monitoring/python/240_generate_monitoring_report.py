#!/usr/bin/env python3
import argparse
import json
import os
from datetime import datetime, timezone
from pathlib import Path
from typing import Dict, Any

from pyspark.sql import SparkSession
from pyspark.sql.functions import col, count as f_count, max as f_max, sum as f_sum


def safe_count(spark: SparkSession, path: str) -> Dict[str, Any]:
    try:
        df = spark.read.parquet(path)
        return {"status": "OK", "row_count": df.count(), "path": path, "error": None}
    except Exception as exc:
        return {"status": "ERROR", "row_count": 0, "path": path, "error": str(exc)[:500]}


def read_checkpoint(spark: SparkSession, path: str) -> Dict[str, Any]:
    result = safe_count(spark, path)
    if result["status"] != "OK":
        return result
    try:
        df = spark.read.parquet(path)
        row = df.orderBy(col("last_processed_batch_id").desc()).limit(1).collect()[0]
        result.update({
            "last_processed_batch_id": int(row["last_processed_batch_id"]),
            "checkpoint_status": row["checkpoint_status"],
        })
    except Exception as exc:
        result.update({"status": "ERROR", "error": str(exc)[:500]})
    return result


def hdfs_exists(spark: SparkSession, path: str) -> bool:
    try:
        jvm = spark._jvm
        conf = spark._jsc.hadoopConfiguration()
        fs = jvm.org.apache.hadoop.fs.FileSystem.get(conf)
        return fs.exists(jvm.org.apache.hadoop.fs.Path(path))
    except Exception:
        return False


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--project-root", required=True)
    parser.add_argument("--report-dir", required=True)
    parser.add_argument("--hdfs-root", required=True)
    parser.add_argument("--spark-root", required=True)
    parser.add_argument("--analytics-root", required=True)
    parser.add_argument("--incremental-root", required=True)
    args = parser.parse_args()

    report_dir = Path(args.report_dir)
    report_dir.mkdir(parents=True, exist_ok=True)

    spark = (
        SparkSession.builder
        .appName("MiniBOP_Phase24_ObservabilityMonitoring")
        .master("local[*]")
        .config("spark.sql.shuffle.partitions", "1")
        .getOrCreate()
    )
    spark.sparkContext.setLogLevel("WARN")

    generated_at = datetime.now(timezone.utc).isoformat()

    paths = {
        "spark_trade_curated": f"{args.spark_root}/trade_curated",
        "spark_summary_by_currency": f"{args.spark_root}/trade_summary_by_currency",
        "analytics_silver_trade_enriched": f"{args.analytics_root}/silver_trade_enriched",
        "analytics_gold_dashboard_metrics": f"{args.analytics_root}/gold_dashboard_metrics",
        "incremental_bronze_batches": f"{args.incremental_root}/bronze_incremental_batches",
        "incremental_current_trades": f"{args.incremental_root}/silver_current_trades",
        "incremental_trade_history": f"{args.incremental_root}/silver_trade_history",
        "incremental_change_log": f"{args.incremental_root}/silver_trade_change_log",
        "incremental_currency_summary": f"{args.incremental_root}/gold_incremental_currency_summary",
        "incremental_metrics": f"{args.incremental_root}/gold_incremental_metrics",
        "incremental_job_history": f"{args.incremental_root}/control_spark_job_history",
    }

    checks: Dict[str, Any] = {}
    for name, path in paths.items():
        checks[name] = safe_count(spark, path)

    checks["incremental_checkpoint"] = read_checkpoint(
        spark, f"{args.incremental_root}/control_incremental_checkpoint"
    )

    hdfs_dirs = {
        "hdfs_trade_landing": f"{args.hdfs_root}/trade",
        "hdfs_hive_layer": f"{args.hdfs_root}/hive",
        "hdfs_spark_layer": f"{args.hdfs_root}/spark",
        "hdfs_analytics_layer": f"{args.hdfs_root}/analytics",
        "hdfs_incremental_layer": f"{args.hdfs_root}/incremental",
    }
    for name, path in hdfs_dirs.items():
        checks[name] = {
            "status": "OK" if hdfs_exists(spark, path) else "ERROR",
            "path": path,
            "exists": hdfs_exists(spark, path),
        }

    # Business sanity checks.
    try:
        current = spark.read.parquet(f"{args.incremental_root}/silver_current_trades")
        duplicate_keys = (
            current.groupBy("external_trade_id")
            .agg(f_count("*").alias("cnt"))
            .where(col("cnt") > 1)
            .count()
        )
        checks["business_no_duplicate_current_trades"] = {
            "status": "OK" if duplicate_keys == 0 else "ERROR",
            "duplicate_keys": duplicate_keys,
        }
    except Exception as exc:
        checks["business_no_duplicate_current_trades"] = {"status": "ERROR", "error": str(exc)[:500]}

    try:
        metrics = spark.read.parquet(f"{args.incremental_root}/gold_incremental_metrics")
        metric_rows = {r["metric_name"]: float(r["metric_value"]) for r in metrics.collect()}
        # Phase 22 writes CURRENT_TRADE_ROWS. Keep TOTAL_CURRENT_TRADES as a
        # compatibility alias in case future versions rename the metric.
        current_trade_metric = metric_rows.get("CURRENT_TRADE_ROWS", metric_rows.get("TOTAL_CURRENT_TRADES"))
        checks["business_incremental_metrics"] = {
            "status": "OK" if current_trade_metric == 6.0 else "ERROR",
            "metrics": metric_rows,
            "expected_current_trade_rows": 6,
            "actual_current_trade_rows": current_trade_metric,
        }
    except Exception as exc:
        checks["business_incremental_metrics"] = {"status": "ERROR", "error": str(exc)[:500]}

    overall_status = "HEALTHY" if all(item.get("status") == "OK" for item in checks.values()) else "DEGRADED"

    report = {
        "project": "Mini BOP",
        "phase": "24 - Observability & Monitoring",
        "generated_at": generated_at,
        "overall_status": overall_status,
        "checks": checks,
    }

    (report_dir / "pipeline_health.json").write_text(json.dumps(report, indent=2, sort_keys=True))

    md_lines = [
        "# Mini BOP - Pipeline Health Report",
        "",
        f"Generated at: `{generated_at}`",
        f"Overall status: **{overall_status}**",
        "",
        "## Checks",
        "",
        "| Check | Status | Rows / Details |",
        "|---|---:|---|",
    ]
    for name, item in sorted(checks.items()):
        details = []
        if "row_count" in item:
            details.append(f"rows={item['row_count']}")
        if "last_processed_batch_id" in item:
            details.append(f"last_batch={item['last_processed_batch_id']}")
        if "duplicate_keys" in item:
            details.append(f"duplicate_keys={item['duplicate_keys']}")
        if "exists" in item:
            details.append(f"exists={item['exists']}")
        if item.get("error"):
            details.append(f"error={item['error']}")
        md_lines.append(f"| `{name}` | {item.get('status')} | {'; '.join(details)} |")

    md_lines.extend([
        "",
        "## Interpretation",
        "",
        "This report validates the operational health of the Mini BOP data platform across HDFS, Spark curated outputs, analytics datasets, incremental datasets, checkpoints and business-level duplicate controls.",
    ])
    (report_dir / "pipeline_health.md").write_text("\n".join(md_lines) + "\n")

    print("============================================================")
    print("MINI BOP PHASE 24 MONITORING SUMMARY")
    print("============================================================")
    print(f"overall_status={overall_status}")
    for name, item in sorted(checks.items()):
        print(f"{name}={item.get('status')} rows={item.get('row_count', 'n/a')}")
    print("Reports:")
    print(report_dir / "pipeline_health.json")
    print(report_dir / "pipeline_health.md")

    spark.stop()

    if overall_status != "HEALTHY":
        raise SystemExit(2)


if __name__ == "__main__":
    main()
