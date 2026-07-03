#!/usr/bin/env bash
set -euo pipefail

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }
has_jps() { jps 2>/dev/null | grep -q "$1"; }

print_section "MINI BOP - BOOTSTRAP 01 - START HADOOP/YARN"

if ! command -v jps >/dev/null 2>&1; then
  echo "ERROR: jps not found. Check Java/JDK installation."
  exit 1
fi

if ! has_jps NameNode; then
  echo "Starting HDFS..."
  start-dfs.sh
else
  echo "NameNode already running."
fi

if ! has_jps ResourceManager; then
  echo "Starting YARN..."
  start-yarn.sh
else
  echo "ResourceManager already running."
fi

sleep 2

print_section "Running Java processes"
jps

print_section "HDFS smoke test"
hdfs dfs -ls / || true

print_section "Mini BOP HDFS root"
hdfs dfs -ls /data/mini_bop || true

echo "BOOTSTRAP_01_STATUS=COMPLETED"
