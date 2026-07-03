#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
API_PORT="${MINI_BOP_API_PORT:-8010}"
AIRFLOW_HOME_DEFAULT="$HOME/airflow-mini-bop/airflow_home"
AIRFLOW_VENV_DEFAULT="$HOME/airflow-mini-bop/.venv"

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }
check_cmd() {
  local cmd="$1"
  local label="$2"
  if command -v "$cmd" >/dev/null 2>&1; then
    echo "[OK] $label: $(command -v "$cmd")"
  else
    echo "[WARN] $label not found: $cmd"
  fi
}

print_section "MINI BOP - BOOTSTRAP 00 - ENVIRONMENT CHECK"
echo "Project root : $PROJECT_ROOT"
echo "API port     : $API_PORT"
echo "Airflow home : ${AIRFLOW_HOME:-$AIRFLOW_HOME_DEFAULT}"
echo "Airflow venv : $AIRFLOW_VENV_DEFAULT"
echo ""

print_section "Core tools"
check_cmd java "Java"
check_cmd hadoop "Hadoop"
check_cmd hdfs "HDFS CLI"
check_cmd yarn "YARN CLI"
check_cmd hive "Hive"
check_cmd beeline "Beeline"
check_cmd spark-submit "Spark Submit"
check_cmd python "Python"
check_cmd pip "Pip"
check_cmd airflow "Airflow"
check_cmd uvicorn "Uvicorn"

echo ""
print_section "Versions"
(java -version 2>&1 | head -n 3) || true
(hadoop version 2>/dev/null | head -n 1) || true
(spark-submit --version 2>&1 | head -n 8) || true
(python --version 2>&1) || true
(airflow version 2>/dev/null) || true

echo ""
print_section "Filesystem and key directories"
for path in "$PROJECT_ROOT" "$PROJECT_ROOT/api" "$PROJECT_ROOT/airflow" "$PROJECT_ROOT/hadoop" "$PROJECT_ROOT/hive" "$PROJECT_ROOT/spark" "$PROJECT_ROOT/monitoring" "$PROJECT_ROOT/data/export"; do
  if [ -e "$path" ]; then echo "[OK] $path"; else echo "[WARN] missing: $path"; fi
done

echo ""
print_section "Hadoop processes"
if command -v jps >/dev/null 2>&1; then
  jps || true
else
  echo "[WARN] jps not found. Check JAVA_HOME/JDK installation."
fi

echo ""
print_section "Network ports"
if command -v ss >/dev/null 2>&1; then
  ss -ltnp 2>/dev/null | grep -E ":(9000|9870|8088|8080|$API_PORT)" || echo "[INFO] No key Mini BOP ports currently listening."
else
  echo "[WARN] ss command not available."
fi

echo ""
echo "BOOTSTRAP_00_STATUS=COMPLETED"
