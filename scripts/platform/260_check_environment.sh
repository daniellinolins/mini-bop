#!/usr/bin/env bash
set -u

 echo "============================================================"
 echo "MINI BOP - PHASE 26"
 echo "LOCAL PLATFORM ENVIRONMENT CHECK"
 echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
API_PORT=${MINI_BOP_API_PORT:-8010}
AIRFLOW_HOME=${AIRFLOW_HOME:-$HOME/airflow-mini-bop/airflow_home}
SPARK_HOME=${SPARK_HOME:-$HOME/spark}
HADOOP_HOME=${HADOOP_HOME:-$HOME/hadoop}

 echo "Project root: $PROJECT_ROOT"
 echo "API port:     $API_PORT"
 echo "AIRFLOW_HOME: $AIRFLOW_HOME"
 echo "SPARK_HOME:   $SPARK_HOME"
 echo "HADOOP_HOME:  $HADOOP_HOME"
 echo

STATUS=0

check_cmd() {
  local cmd=$1
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "OK:   $cmd -> $(command -v "$cmd")"
  else
    echo "WARN: $cmd not found"
    STATUS=1
  fi
}

check_file() {
  local file=$1
  if [ -e "$file" ]; then
    echo "OK:   $file"
  else
    echo "WARN: missing $file"
    STATUS=1
  fi
}

 echo "1) Core commands"
check_cmd java
check_cmd hadoop
check_cmd hdfs
check_cmd spark-submit
check_cmd python
check_cmd airflow
check_cmd curl

 echo
 echo "2) Important project files"
check_file "$PROJECT_ROOT/api/main.py"
check_file "$PROJECT_ROOT/api/scripts/251_run_api.sh"
check_file "$PROJECT_ROOT/monitoring/scripts/240_collect_pipeline_metrics.sh"
check_file "$PROJECT_ROOT/monitoring/reports/pipeline_health.json"
check_file "$PROJECT_ROOT/hadoop/spark/220_run_spark_phase22.sh"

 echo
 echo "3) Hadoop JVM processes"
if command -v jps >/dev/null 2>&1; then
  jps || true
else
  echo "WARN: jps not found"
  STATUS=1
fi

 echo
 echo "4) HDFS check"
if command -v hdfs >/dev/null 2>&1; then
  hdfs dfs -ls /data/mini_bop >/tmp/mini_bop_phase26_hdfs_check.txt 2>&1
  if [ $? -eq 0 ]; then
    echo "OK:   HDFS /data/mini_bop reachable"
    cat /tmp/mini_bop_phase26_hdfs_check.txt
  else
    echo "WARN: HDFS not reachable or /data/mini_bop missing"
    cat /tmp/mini_bop_phase26_hdfs_check.txt
    STATUS=1
  fi
fi

 echo
 echo "5) API port check"
if command -v ss >/dev/null 2>&1; then
  if ss -ltnp 2>/dev/null | grep -q ":${API_PORT}"; then
    echo "INFO: port ${API_PORT} is already in use. This is OK if the Mini BOP API is running."
    ss -ltnp 2>/dev/null | grep ":${API_PORT}" || true
  else
    echo "OK:   port ${API_PORT} appears free"
  fi
else
  echo "WARN: ss not found"
fi

 echo
if [ $STATUS -eq 0 ]; then
  echo "PHASE26_LOCAL_ENV_CHECK=OK"
else
  echo "PHASE26_LOCAL_ENV_CHECK=WARNINGS"
fi
