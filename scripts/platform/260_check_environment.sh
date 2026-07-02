#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "MINI BOP - PHASE 26"
echo "PLATFORM ENVIRONMENT CHECK"
echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
API_PORT=${MINI_BOP_API_PORT:-8010}

echo "Project root: $PROJECT_ROOT"
echo "API port:     $API_PORT"
echo

check_cmd() {
  local cmd=$1
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK: $cmd -> $(command -v "$cmd")"
  else
    echo "WARN: $cmd not found"
  fi
}

check_cmd java
check_cmd hadoop
check_cmd hdfs
check_cmd spark-submit
check_cmd python
check_cmd airflow
check_cmd docker

echo
echo "Hadoop JVM processes:"
if command -v jps >/dev/null 2>&1; then
  jps || true
else
  echo "WARN: jps not found"
fi

echo
echo "HDFS check:"
if command -v hdfs >/dev/null 2>&1; then
  hdfs dfs -ls /data/mini_bop || echo "WARN: HDFS not reachable or /data/mini_bop missing"
else
  echo "WARN: hdfs command not found"
fi

echo
echo "Port check:"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep ":${API_PORT}" || echo "OK: port ${API_PORT} appears free"
else
  echo "WARN: ss not found"
fi

echo
echo "PHASE26_ENV_CHECK_COMPLETED"
