#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"
cd "$PROJECT_ROOT"

if [ -z "${VIRTUAL_ENV:-}" ]; then
  echo "ERROR: activate the shared Mini BOP/Airflow virtualenv first."
  echo "source ~/airflow-mini-bop/.venv/bin/activate"
  exit 1
fi

python -m pip install --upgrade pip setuptools wheel
python -m pip install -r api/requirements.txt

python - <<'PY'
import importlib.util
for module in ["fastapi", "uvicorn", "jinja2"]:
    spec = importlib.util.find_spec(module)
    if spec is None:
        raise SystemExit(f"Missing module: {module}")
    print(f"OK: {module}")
print("API dependencies installed in the active virtualenv.")
print("PySpark is intentionally loaded from SPARK_HOME by api/scripts/251_run_api.sh, not installed by api/requirements.txt.")
PY
