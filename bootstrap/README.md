# Mini BOP Bootstrap Platform

This folder provides a local, repeatable startup flow for the Mini BOP demo environment.

## Recommended order

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop

source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_PORT=8010

bash bootstrap/00_check_environment.sh
bash bootstrap/01_start_hadoop.sh
bash bootstrap/02_start_airflow.sh
bash bootstrap/03_start_api.sh
```

Run validation in a second terminal while the API is running:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
source ~/airflow-mini-bop/.venv/bin/activate
export MINI_BOP_PROJECT_ROOT=/mnt/f/SSD_DEV/windows/projects/mini-bop
export MINI_BOP_API_BASE=http://localhost:8010

bash bootstrap/04_validate_platform.sh
```

## Demo URLs

- Airflow: http://localhost:8080
- Swagger/OpenAPI: http://localhost:8010/docs
- Dashboard: http://localhost:8010/dashboard

## Stop

```bash
bash bootstrap/06_stop_platform.sh
```

Stop Airflow/API foreground terminals manually using `Ctrl+C`.
