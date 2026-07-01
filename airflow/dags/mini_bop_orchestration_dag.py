"""
MINI BOP - Phase 23.1
Airflow orchestration DAG for the Mini BOP end-to-end data pipeline.

This DAG orchestrates the already homologated local pipeline stages:
HDFS/Hive -> Spark Processing -> Spark SQL Analytics -> Spark Incremental.
"""

from __future__ import annotations

import os
from datetime import datetime, timedelta

from airflow import DAG
from airflow.operators.empty import EmptyOperator
from airflow.operators.bash import BashOperator
from airflow.utils.task_group import TaskGroup

PROJECT_ROOT = os.environ.get("MINI_BOP_PROJECT_ROOT", "/mnt/f/SSD_DEV/windows/projects/mini-bop")

DEFAULT_ARGS = {
    "owner": "daniel_lins",
    "depends_on_past": False,
    "email_on_failure": False,
    "email_on_retry": False,
    "retries": 1,
    "retry_delay": timedelta(minutes=2),
    "execution_timeout": timedelta(minutes=60),
}


def mini_bop_bash(task_id: str, command: str, doc_md: str | None = None) -> BashOperator:
    """Create a BashOperator for Mini BOP commands.

    Airflow 2.10 does not accept template_ext as an __init__ argument for BashOperator.
    To avoid TemplateNotFound warnings for inline bash content, we set template_ext
    on the operator instance after creation.
    """
    task = BashOperator(
        task_id=task_id,
        bash_command=f"set -euo pipefail\ncd {PROJECT_ROOT}\n{command}",
        env={
            **os.environ,
            "PROJECT_ROOT": PROJECT_ROOT,
            "MINI_BOP_PROJECT_ROOT": PROJECT_ROOT,
        },
        do_xcom_push=False,
    )
    task.template_ext = ()
    if doc_md:
        task.doc_md = doc_md
    return task


with DAG(
    dag_id="mini_bop_end_to_end_pipeline",
    description="Mini BOP Oracle/HDFS/Hive/Spark orchestration pipeline",
    default_args=DEFAULT_ARGS,
    start_date=datetime(2026, 7, 1),
    schedule=None,
    catchup=False,
    max_active_runs=1,
    tags=["mini-bop", "data-engineering", "oracle", "hadoop", "hive", "spark"],
    doc_md="""
# Mini BOP End-to-End Pipeline

This DAG orchestrates the Mini BOP data engineering laboratory:

1. HDFS landing zone preparation
2. Oracle export upload to HDFS
3. Hive external table refresh and validation
4. Spark processing layer
5. Spark SQL analytics layer
6. Spark incremental / Delta Lake concepts layer
7. Final HDFS inventory

The DAG assumes that Oracle export files already exist in `data/export` and that
Hadoop/HDFS, Hive and Spark are available in the WSL environment.
""",
) as dag:
    start = EmptyOperator(task_id="start")

    check_environment = mini_bop_bash(
        task_id="check_environment",
        command="""
        echo 'Checking Mini BOP orchestration environment'
        echo "PROJECT_ROOT=$PROJECT_ROOT"
        java -version
        hadoop version | head -n 5
        spark-submit --version
        jps
        hdfs dfs -ls /data/mini_bop || true
        """,
        doc_md="Validate Java, Hadoop, Spark, HDFS/YARN processes and Mini BOP HDFS root.",
    )

    with TaskGroup(group_id="hdfs_and_hive_layer", tooltip="HDFS landing and Hive external table layer") as hdfs_and_hive_layer:
        create_hdfs_dirs = mini_bop_bash(
            task_id="create_hdfs_dirs",
            command="bash hadoop/hdfs/180_create_hdfs_dirs.sh",
            doc_md="Create the Mini BOP HDFS landing directories.",
        )

        upload_oracle_exports_to_hdfs = mini_bop_bash(
            task_id="upload_oracle_exports_to_hdfs",
            command="""
            bash hadoop/hdfs/181_upload_exports_to_hdfs.sh \
              /mnt/f/SSD_DEV/windows/projects/mini-bop/data/export \
              /data/mini_bop/trade
            """,
            doc_md="Upload Oracle-generated CSV and manifest files into HDFS.",
        )

        run_hive_phase19 = mini_bop_bash(
            task_id="run_hive_phase19",
            command="bash hadoop/hive/190_run_hive_phase19.sh",
            doc_md="Create or refresh Hive raw and curated external-table/query layer.",
        )

        validate_hive_phase19 = mini_bop_bash(
            task_id="validate_hive_phase19",
            command="bash hadoop/hive/191_validate_hive_phase19.sh",
            doc_md="Validate Hive can read the HDFS CSV and curated view correctly.",
        )

        create_hdfs_dirs >> upload_oracle_exports_to_hdfs >> run_hive_phase19 >> validate_hive_phase19

    with TaskGroup(group_id="spark_processing_layer", tooltip="Spark processing, analytics and incremental layers") as spark_processing_layer:
        run_spark_phase20 = mini_bop_bash(
            task_id="run_spark_phase20",
            command="bash hadoop/spark/200_run_spark_phase20.sh",
            doc_md="Run Spark processing engine and generate curated Parquet outputs.",
        )

        validate_spark_phase20 = mini_bop_bash(
            task_id="validate_spark_phase20",
            command="bash hadoop/spark/201_validate_spark_phase20.sh",
            doc_md="Validate Spark Phase 20 curated and summary outputs.",
        )

        run_spark_phase21 = mini_bop_bash(
            task_id="run_spark_phase21",
            command="bash hadoop/spark/210_run_spark_phase21.sh",
            doc_md="Run Spark SQL analytics layer and generate Silver/Gold datasets.",
        )

        validate_spark_phase21 = mini_bop_bash(
            task_id="validate_spark_phase21",
            command="bash hadoop/spark/211_validate_spark_phase21.sh",
            doc_md="Validate Spark SQL analytics outputs.",
        )

        run_spark_phase22 = mini_bop_bash(
            task_id="run_spark_phase22",
            command="bash hadoop/spark/220_run_spark_phase22.sh",
            doc_md="Run Spark incremental processing and Delta Lake concept simulation.",
        )

        validate_spark_phase22 = mini_bop_bash(
            task_id="validate_spark_phase22",
            command="bash hadoop/spark/221_validate_spark_phase22.sh",
            doc_md="Validate incremental current/history/change-log/checkpoint outputs.",
        )

        (
            run_spark_phase20
            >> validate_spark_phase20
            >> run_spark_phase21
            >> validate_spark_phase21
            >> run_spark_phase22
            >> validate_spark_phase22
        )

    final_hdfs_inventory = mini_bop_bash(
        task_id="final_hdfs_inventory",
        command="""
        echo 'Final Mini BOP HDFS inventory'
        hdfs dfs -ls /data/mini_bop
        hdfs dfs -ls /data/mini_bop/spark
        hdfs dfs -ls /data/mini_bop/analytics
        hdfs dfs -ls /data/mini_bop/incremental
        """,
        doc_md="List final HDFS outputs generated by the orchestrated pipeline.",
    )

    end = EmptyOperator(task_id="end")

    start >> check_environment >> hdfs_and_hive_layer >> spark_processing_layer >> final_hdfs_inventory >> end
