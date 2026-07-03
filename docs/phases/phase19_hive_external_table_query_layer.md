# Phase 19 — Hive External Table & Query Layer

This phase creates a Hive query layer over the CSV files exported from Oracle to HDFS in Phase 18.

## Design

The Hive layer uses two stages:

1. `ext_trade_core_csv_raw` — external table reading the CSV as raw strings.
2. `vw_trade_core_csv` — typed curated view that filters the header row and casts columns.
3. `ext_trade_core_csv` — compatibility view pointing to the curated view.

The raw table intentionally includes the CSV header row. The curated view removes it with:

```sql
WHERE TRIM(trade_id_txt) RLIKE '^[0-9]+$'
```

This keeps ingestion robust and prevents numeric aggregations from trying to cast header values such as `amount_eur` or `notional_amount`.

## Commands

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
bash hadoop/hive/190_run_hive_phase19.sh
bash hadoop/hive/191_validate_hive_phase19.sh
```

## Expected validation

```text
RAW_ROW_COUNT_INCLUDING_HEADER = 6
CURATED_ROW_COUNT = 5
trade_status = PROCESSED, 5
hive_phase19_status = PASSED
```
