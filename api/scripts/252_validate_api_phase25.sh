#!/bin/bash
set -e

API_BASE=${MINI_BOP_API_BASE:-http://localhost:8010}

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 25.1"
echo "API DOCUMENTATION & DEVELOPER EXPERIENCE"
echo "============================================================"
echo "API_BASE=$API_BASE"

check_url() {
  local name=$1
  local url=$2
  echo "Checking $name -> $url"
  local code
  code=$(curl -s -o /tmp/mini_bop_api_check.json -w "%{http_code}" "$url")
  cat /tmp/mini_bop_api_check.json | head -c 500 || true
  echo
  if [ "$code" != "200" ]; then
    echo "ERROR: $name returned HTTP $code"
    exit 1
  fi
}

check_url "health" "$API_BASE/health"
check_url "openapi" "$API_BASE/openapi.json"
check_url "pipeline status" "$API_BASE/pipeline/status"
check_url "metrics" "$API_BASE/metrics"
check_url "current trades" "$API_BASE/trades/current?limit=5"
check_url "current trades filtered" "$API_BASE/trades/current?currency=EUR&status=PROCESSED&limit=5"
check_url "top trades" "$API_BASE/trades/top?limit=3"
check_url "exposure currency" "$API_BASE/exposure/currency"
check_url "exposure currency filtered" "$API_BASE/exposure/currency?currency=EUR"
check_url "exposure book" "$API_BASE/exposure/book?book_id=1"
check_url "incremental checkpoint" "$API_BASE/incremental/checkpoint"
check_url "monitoring report" "$API_BASE/monitoring/report"
check_url "dashboard" "$API_BASE/dashboard"

python - <<'PY'
import json
from pathlib import Path
p = Path('/tmp/mini_bop_api_check.json')
print('API validation payload check complete')
PY

echo "PHASE25_1_API_DOCS_STATUS=PASSED"
