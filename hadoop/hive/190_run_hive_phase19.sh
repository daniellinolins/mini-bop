#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="/mnt/f/SSD_DEV/windows/projects/mini-bop"
HIVE_CMD="beeline -u jdbc:hive2://"
SOURCE_HDFS_DIR="/data/mini_bop/trade"
HIVE_HDFS_DIR="/data/mini_bop/hive/trade_core_csv"

echo "============================================================"
echo "MINI BOP - PHASE 19"
echo "HIVE EXTERNAL TABLE & QUERY LAYER"
echo "============================================================"
echo "Project root: ${PROJECT_ROOT}"
echo "Hive command: ${HIVE_CMD}"
echo "Source HDFS dir: ${SOURCE_HDFS_DIR}"
echo "Hive table HDFS dir: ${HIVE_HDFS_DIR}"

cd "${PROJECT_ROOT}"

echo "Checking HDFS landing zone..."
hdfs dfs -ls "${SOURCE_HDFS_DIR}"

echo "Preparing Hive-only CSV directory..."
echo "This avoids Hive reading manifest files as CSV rows."
hdfs dfs -mkdir -p "${HIVE_HDFS_DIR}"
hdfs dfs -rm -f "${HIVE_HDFS_DIR}"/*.csv >/dev/null 2>&1 || true
hdfs dfs -cp -f "${SOURCE_HDFS_DIR}"/*.csv "${HIVE_HDFS_DIR}/"

echo "CSV files available for Hive:"
hdfs dfs -ls "${HIVE_HDFS_DIR}"

echo "Creating Hive database..."
${HIVE_CMD} -f hive/ddl/190_create_hive_database.hql

echo "Creating external raw table and curated typed view..."
${HIVE_CMD} -f hive/ddl/191_create_external_trade_table.hql

echo "Running validation queries..."
${HIVE_CMD} -f hive/ddl/192_validate_hive_trade_queries.hql

echo "Phase 19 Hive objects created successfully."
