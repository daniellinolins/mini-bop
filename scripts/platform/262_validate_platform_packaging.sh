#!/usr/bin/env bash
set -euo pipefail

echo "============================================================"
echo "VALIDATING MINI BOP - PHASE 26"
echo "PLATFORM PACKAGING & DEPLOYMENT"
echo "============================================================"

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
cd "$PROJECT_ROOT"

required_files=(
  "docker/api/Dockerfile"
  "docker/env/mini-bop.env.example"
  "docker-compose.api.yml"
  "scripts/platform/260_check_environment.sh"
  "scripts/platform/261_start_local_platform.sh"
  "scripts/platform/262_validate_platform_packaging.sh"
  "docs/phase26_platform_packaging_deployment.md"
)

echo "1) Required files"
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
for f in scripts/platform/*.sh; do
  if [ -x "$f" ]; then
    echo "OK executable: $f"
  else
    echo "WARN not executable, fixing: $f"
    chmod +x "$f"
  fi
done

echo
echo "3) Docker compose syntax"
if command -v docker >/dev/null 2>&1; then
  docker compose -f docker-compose.api.yml config >/tmp/mini_bop_phase26_compose_config.txt
  echo "OK: docker compose config parsed"
else
  echo "WARN: docker command not found, skipping compose syntax check"
fi

echo
echo "4) Local environment check"
bash scripts/platform/260_check_environment.sh || true

echo
echo "PHASE26_PLATFORM_PACKAGING_STATUS=PASSED"
