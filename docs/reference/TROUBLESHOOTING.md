# Troubleshooting

This document summarizes common issues and recovery procedures.

## HDFS Connection Refused

Symptom:

```text
Call From ... to localhost:9000 failed on connection exception
```

Resolution:

```bash
start-dfs.sh
jps
hdfs dfs -ls /
```

Ensure `NameNode` and `DataNode` are running.

## NameNode Not Running

Check processes:

```bash
jps
```

Start HDFS:

```bash
start-dfs.sh
```

## Hive Command Not Found

Ensure Hive is installed and available in `PATH`:

```bash
which hive
hive --version
```

## Airflow DAG Not Visible

Refresh the DAG installation:

```bash
bash airflow/scripts/230_install_airflow_dag.sh
airflow dags list
```

## Airflow Import Error

Inspect import errors:

```bash
airflow dags list-import-errors
```

## PySpark Module Not Found

When using the local API, ensure the API startup script configures Spark-related Python paths:

```bash
bash api/scripts/251_run_api.sh
```

## WSL Read-only Filesystem

Symptoms include failures creating files in `/tmp` or `$HOME`.

Resolution:

```powershell
wsl --shutdown
wsl
```

Then verify:

```bash
touch ~/teste.txt
mount | grep " / "
```

The root filesystem should be mounted as `rw`.

## Dashboard Cannot Find Monitoring Report

Run:

```bash
bash monitoring/scripts/240_collect_pipeline_metrics.sh
```

Then restart the API.

## CRLF Issues in Bash Scripts

Symptom:

```text
set: pipefail: invalid option name
```

Resolution:

```bash
sudo apt-get install -y dos2unix
dos2unix bootstrap/*.sh airflow/scripts/*.sh api/scripts/*.sh scripts/platform/*.sh monitoring/scripts/*.sh
```

## Port Already in Use

If port `8010` is unavailable, configure another port:

```bash
export MINI_BOP_API_PORT=8011
bash api/scripts/251_run_api.sh
```
