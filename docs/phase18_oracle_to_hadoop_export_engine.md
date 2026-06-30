# Mini BOP - Phase 18

## Oracle to Hadoop Export Engine

This phase creates the first bridge between the Oracle processing platform and the Hadoop landing zone.

## Main Goal

Export processed trades from Oracle `TRADE` into CSV files with manifest/control metadata, preparing the data for ingestion into HDFS.

## Components

### Tables

- `EXPORT_JOB`
- `EXPORT_FILE`
- `EXPORT_MANIFEST`

### Package

- `PKG_HADOOP_EXPORT`

### Views

- `VW_EXPORT_JOB_SUMMARY`
- `VW_EXPORT_FILES`
- `VW_EXPORT_MANIFEST`
- `VW_LATEST_EXPORT_HEALTH`

### Hadoop Scripts

- `hadoop/hdfs/180_create_hdfs_dirs.sh`
- `hadoop/hdfs/181_upload_exports_to_hdfs.sh`

## Export Flow

```text
Oracle TRADE
   |
   v
PKG_HADOOP_EXPORT
   |
   +--> CSV data file
   +--> Manifest file
   +--> EXPORT_JOB / EXPORT_FILE / EXPORT_MANIFEST
   |
   v
Local landing directory
   |
   v
HDFS /data/mini_bop/trade
```

## Execution

```sql
@scripts/run_phase18_as_mini_bop.sql
@scripts/validate_phase18.sql
```

## HDFS Upload

From WSL:

```bash
cd /mnt/f/SSD_DEV/windows/projects/mini-bop
bash hadoop/hdfs/180_create_hdfs_dirs.sh
bash hadoop/hdfs/181_upload_exports_to_hdfs.sh /mnt/f/SSD_DEV/windows/projects/mini-bop/data/export /data/mini_bop/trade
```

## Notes

The Oracle DIRECTORY object `MINI_BOP_EXPORT_DIR` points to:

```text
F:\SSD_DEV\windows\projects\mini-bop\data\export
```

If your Oracle server runs inside Linux or Docker, create or replace the directory using a path visible to the Oracle server.

Example:

```sql
CREATE OR REPLACE DIRECTORY MINI_BOP_EXPORT_DIR AS '/tmp/mini_bop_exports';
GRANT READ, WRITE ON DIRECTORY MINI_BOP_EXPORT_DIR TO MINI_BOP;
```

## Interview Talking Points

- Why create an export control layer before Hadoop?
- Why use a manifest file?
- How do you validate exported row counts?
- How would this evolve to Sqoop, Parquet or Spark ingestion?
- What is the difference between operational core data and data lake landing data?
