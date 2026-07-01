#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/mnt/f/SSD_DEV/windows/projects/mini-bop"
HIVE_CMD="beeline -u jdbc:hive2://"

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 19"
echo "============================================================"

cd "${PROJECT_ROOT}"

echo "1) Hadoop processes"
jps

echo "2) HDFS export files"
hdfs dfs -ls /data/mini_bop/trade

echo "3) Hive CSV directory"
hdfs dfs -ls /data/mini_bop/hive/trade_core_csv

echo "4) Manifest"
hdfs dfs -cat /data/mini_bop/trade/trade_export_1_manifest.txt

echo "5) Hive validation queries"
${HIVE_CMD} -f hive/ddl/192_validate_hive_trade_queries.hql

echo "Phase 19 validation completed."
