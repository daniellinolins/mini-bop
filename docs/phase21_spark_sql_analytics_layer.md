# Mini BOP - Phase 21 - Spark SQL Analytics Layer

## Objective

Phase 21 builds the analytical layer on top of the Phase 20 Spark curated Parquet data.

The goal is to move from raw processing to business analytics, using Spark SQL and DataFrame APIs to produce Silver and Gold analytical datasets.

## Input

```text
hdfs://localhost:9000/data/mini_bop/spark/trade_curated
```

## Outputs

```text
hdfs://localhost:9000/data/mini_bop/analytics/silver_trade_enriched
hdfs://localhost:9000/data/mini_bop/analytics/gold_exposure_by_currency
hdfs://localhost:9000/data/mini_bop/analytics/gold_exposure_by_book
hdfs://localhost:9000/data/mini_bop/analytics/gold_exposure_by_portfolio
hdfs://localhost:9000/data/mini_bop/analytics/gold_exposure_by_counterparty
hdfs://localhost:9000/data/mini_bop/analytics/gold_top_trades_by_amount
hdfs://localhost:9000/data/mini_bop/analytics/gold_dashboard_metrics
```

## Execution

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
bash hadoop/spark/210_run_spark_phase21.sh
```

## Validation

```bash
bash hadoop/spark/211_validate_spark_phase21.sh
```

Expected markers:

```text
silver_count=5
currency_rows=2
dashboard_metric_rows=5
SPARK_PHASE21_STATUS=PASSED
```

## Implemented analytics

### Silver layer

`silver_trade_enriched` adds analytical fields:

- `signed_amount_eur`
- `exposure_bucket`
- `settlement_lag_days`
- `analytics_created_at`

### Gold layer

The gold datasets aggregate exposures by:

- currency
- book
- portfolio
- counterparty
- top trades by amount
- dashboard-level metrics

## Interview notes

This phase demonstrates:

- Spark SQL
- DataFrame transformations
- Parquet output
- analytical layering
- silver/gold data lake design
- financial exposure aggregation
- basic risk-style analytics
