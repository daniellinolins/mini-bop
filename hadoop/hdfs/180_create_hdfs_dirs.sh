#!/usr/bin/env bash
set -euo pipefail

hdfs dfs -mkdir -p /data/mini_bop/trade
hdfs dfs -mkdir -p /data/mini_bop/archive/trade
hdfs dfs -chmod -R 775 /data/mini_bop

echo "HDFS landing zone created: /data/mini_bop/trade"
