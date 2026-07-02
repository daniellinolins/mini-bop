# Mini BOP - Phase 26
# FastAPI application container.
# Hadoop/HDFS/Spark remain external/local services in this phase.

FROM python:3.12-slim

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    MINI_BOP_API_PORT=8010 \
    MINI_BOP_HDFS_BASE=hdfs://host.docker.internal:9000/data/mini_bop

WORKDIR /app

RUN apt-get update \
    && apt-get install -y --no-install-recommends curl ca-certificates \
    && rm -rf /var/lib/apt/lists/*

COPY api/requirements.txt /tmp/requirements.txt
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r /tmp/requirements.txt

COPY api /app/api

EXPOSE 8010

CMD ["sh", "-c", "uvicorn api.main:app --host 0.0.0.0 --port ${MINI_BOP_API_PORT}"]
