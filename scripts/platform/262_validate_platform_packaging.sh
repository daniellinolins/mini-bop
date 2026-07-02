#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 26"
echo "LOCAL PLATFORM PACKAGING & DEMO READINESS"
echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
cd "$PROJECT_ROOT"

required_files=(
  "config/mini-bop.local.env.example"
  "scripts/platform/260_check_environment.sh"
  "scripts/platform/261_start_local_platform.sh"
  "scripts/platform/262_validate_platform_packaging.sh"
  "docs/phase26_platform_packaging_deployment.md"
  "api/scripts/250_install_api_deps.sh"
  "api/scripts/251_run_api.sh"
  "api/scripts/252_validate_api_phase25.sh"
)

echo "1) Required local packaging files"
for f in "${required_files[@]}"; do
  if [ -f "$f" ]; then
    echo "OK: $f"
  else
    echo "ERROR: missing $f"
    exit 1
  fi
done

echo
echo "2) Script permissions"
for f in scripts/platform/*.sh api/scripts/*.sh monitoring/scripts/*.sh; do
  if [ -f "$f" ]; then
    if [ -x "$f" ]; then
      echo "OK executable: $f"
    else
      echo "WARN not executable, fixing: $f"
      chmod +x "$f"
    fi
  fi
done

echo
echo "3) API requirements sanity check"
if grep -q '^pyspark==' api/requirements.txt; then
  echo "ERROR: api/requirements.txt should not install pyspark for local packaging."
  echo "PySpark is loaded from SPARK_HOME by api/scripts/251_run_api.sh."
  exit 1
fi
echo "OK: api/requirements.txt does not force PySpark installation"

echo
echo "4) Local environment check"
bash scripts/platform/260_check_environment.sh || true

echo
echo "PHASE26_LOCAL_PLATFORM_PACKAGING_STATUS=PASSED"
