#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"
BASE_URL="${MINI_BOP_API_URL:-http://localhost:8000}"

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 25"
echo "REST API & DASHBOARD"
echo "============================================================"

for endpoint in "/health" "/pipeline/status" "/metrics" "/trades/current" "/trades/top" "/exposure/currency" "/exposure/book" "/incremental/checkpoint" "/monitoring/report"; do
  echo "Checking ${endpoint}"
  curl -fsS "${BASE_URL}${endpoint}" > /tmp/mini_bop_api_response.json
  python3 - <<'PY'
import json
with open('/tmp/mini_bop_api_response.json', 'r', encoding='utf-8') as f:
    data=json.load(f)
print('OK json keys=', ','.join(list(data.keys())[:8]))
PY
done

echo "Checking dashboard HTML"
curl -fsS "${BASE_URL}/dashboard" | grep -q "Mini BOP Analytics Dashboard"

echo "PHASE25_API_STATUS=PASSED"
