# Mini BOP - Phase 25.1 - API Documentation & Developer Experience

This refinement improves the REST API created in Phase 25 by making the Swagger/OpenAPI experience clearer and safer for technical demonstration.

## Improvements

- Added response models with Pydantic.
- Added endpoint tags: Health, Monitoring, Trades, Analytics, Incremental, Dashboard.
- Added descriptions, examples and parameter constraints.
- Added clearer error responses when HDFS/Spark outputs are unavailable.
- Standardized API execution on port 8010 to avoid port conflicts on Windows.
- Reused the Airflow virtualenv and Spark local installation instead of creating a venv inside the NTFS project folder.

## Validation

Start HDFS/YARN first if needed:

```bash
start-dfs.sh
start-yarn.sh
hdfs dfs -ls /data/mini_bop
```

Start the API:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
bash api/scripts/251_run_api.sh
```

Validate in another terminal:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
bash api/scripts/252_validate_api_phase25.sh
```

Expected result:

```text
PHASE25_1_API_DOCS_STATUS=PASSED
```
