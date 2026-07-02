#!/bin/bash

set -e

PROJECT_ROOT=${MINI_BOP_PROJECT_ROOT:-$(pwd)}

cd "$PROJECT_ROOT"

if [ -z "$VIRTUAL_ENV" ]; then
    echo "ERROR: activate the Airflow virtualenv first."
    echo "source ~/airflow-mini-bop/.venv/bin/activate"
    exit 1
fi

export SPARK_HOME=${SPARK_HOME:-$HOME/spark}

PY4J_ZIP=$(ls "$SPARK_HOME"/python/lib/py4j-*-src.zip | head -n 1)

export PYTHONPATH="$PROJECT_ROOT:$SPARK_HOME/python:$SPARK_HOME/python/lib/pyspark.zip:$PY4J_ZIP:${PYTHONPATH:-}"

echo "=============================================="
echo " MINI BOP REST API"
echo "=============================================="
echo "SPARK_HOME=$SPARK_HOME"
echo "PY4J_ZIP=$PY4J_ZIP"

uvicorn api.main:app \
    --host 0.0.0.0 \
    --port 8010