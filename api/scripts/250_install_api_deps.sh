#!/usr/bin/env bash
set -euo pipefail
PROJECT_ROOT="${MINI_BOP_PROJECT_ROOT:-/mnt/f/SSD_DEV/windows/projects/mini-bop}"
cd "$PROJECT_ROOT"
python3 -m venv api/.venv
source api/.venv/bin/activate
pip install --upgrade pip setuptools wheel
pip install -r api/requirements.txt
# Link PySpark from Spark installation if pip environment does not include it.
python - <<'PY'
try:
    import pyspark  # noqa
    print('PySpark available in API venv')
except Exception:
    print('PySpark not in venv; API scripts will use SPARK_HOME python path via run script')
PY
