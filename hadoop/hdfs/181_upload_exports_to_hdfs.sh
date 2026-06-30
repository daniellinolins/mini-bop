#!/usr/bin/env bash
set -euo pipefail

LOCAL_EXPORT_DIR="${1:-/mnt/f/SSD_DEV/windows/projects/mini-bop/data/export}"
HDFS_TARGET_DIR="${2:-/data/mini_bop/trade}"

if [[ ! -d "$LOCAL_EXPORT_DIR" ]]; then
  echo "Local export directory not found: $LOCAL_EXPORT_DIR" >&2
  exit 1
fi

hdfs dfs -mkdir -p "$HDFS_TARGET_DIR"

for file in "$LOCAL_EXPORT_DIR"/trade_export_*; do
  [[ -e "$file" ]] || { echo "No export files found in $LOCAL_EXPORT_DIR"; exit 0; }
  echo "Uploading $file -> $HDFS_TARGET_DIR"
  hdfs dfs -put -f "$file" "$HDFS_TARGET_DIR/"
done

echo "Uploaded files:"
hdfs dfs -ls "$HDFS_TARGET_DIR"
