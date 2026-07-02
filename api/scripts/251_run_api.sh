#!/bin/bash
set -e

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}
cd "$PROJECT_ROOT"

if [ -z "${VIRTUAL_ENV:-}" ]; then
    echo "ERROR: activate the Airflow virtualenv first."
    echo "source ~/airflow-mini-bop/.venv/bin/activate"
    exit 1
fi

export SPARK_HOME=${SPARK_HOME:-$HOME/spark}
PY4J_ZIP=$(ls "$SPARK_HOME"/python/lib/py4j-*-src.zip | head -n 1)

mkdir -p "$HOME/spark-tmp"
export TMPDIR=$HOME/spark-tmp
export SPARK_LOCAL_DIRS=$HOME/spark-tmp
export JAVA_TOOL_OPTIONS="-Djava.io.tmpdir=$HOME/spark-tmp ${JAVA_TOOL_OPTIONS:-}"
export PYTHONPATH="$PROJECT_ROOT:$SPARK_HOME/python:$SPARK_HOME/python/lib/pyspark.zip:$PY4J_ZIP:${PYTHONPATH:-}"

API_PORT=${MINI_BOP_API_PORT:-8010}

echo "=============================================="
echo " MINI BOP REST API"
echo "=============================================="
echo "SPARK_HOME=$SPARK_HOME"
echo "PY4J_ZIP=$PY4J_ZIP"
echo "API_PORT=$API_PORT"

uvicorn api.main:app --host 0.0.0.0 --port "$API_PORT"
