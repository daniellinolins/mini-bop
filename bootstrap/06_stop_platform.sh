#!/usr/bin/env bash
set -euo pipefail

print_section() { echo "============================================================"; echo "$1"; echo "============================================================"; }

print_section "MINI BOP - BOOTSTRAP 06 - STOP PLATFORM"
echo "This script stops Hadoop/YARN processes."
echo "Stop API/Airflow foreground terminals manually with Ctrl+C when needed."

if command -v stop-yarn.sh >/dev/null 2>&1; then
  stop-yarn.sh || true
fi

if command -v stop-dfs.sh >/dev/null 2>&1; then
  stop-dfs.sh || true
fi

print_section "Remaining Java processes"
jps || true

echo "BOOTSTRAP_06_STATUS=COMPLETED"
