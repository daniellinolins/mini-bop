#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"
REPORT_DIR="$PROJECT_ROOT/monitoring/reports"

cd "$PROJECT_ROOT"

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 24"
echo "OBSERVABILITY & MONITORING"
echo "============================================================"

echo "1) Required report files"
for file in \
  "$REPORT_DIR/pipeline_health.json" \
  "$REPORT_DIR/pipeline_health.md" \
  "$REPORT_DIR/hdfs_inventory.txt" \
  "$REPORT_DIR/jps_status.txt" \
  "$REPORT_DIR/airflow_dag_status.txt"
do
  if [[ ! -s "$file" ]]; then
    echo "Missing or empty report: $file"
    exit 1
  fi
  echo "OK: $file"
done

echo "2) Validating JSON status"
python3 - <<PY
import json
from pathlib import Path
p = Path('$REPORT_DIR/pipeline_health.json')
data = json.loads(p.read_text())
print('overall_status=' + data.get('overall_status', 'UNKNOWN'))
print('generated_at=' + data.get('generated_at', ''))
checks = data.get('checks', {})
for key in sorted(checks):
    item = checks[key]
    print(f"{key}={item.get('status')} rows={item.get('row_count', 'n/a')}")
if data.get('overall_status') != 'HEALTHY':
    raise SystemExit('Expected overall_status=HEALTHY')
PY

echo "3) Report preview"
sed -n '1,120p' "$REPORT_DIR/pipeline_health.md"

echo "OBSERVABILITY_PHASE24_STATUS=PASSED"
