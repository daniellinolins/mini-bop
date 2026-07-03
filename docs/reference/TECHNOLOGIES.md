# Technologies

Mini BOP integrates technologies commonly used in enterprise data platforms.

| Layer | Technology | Responsibility |
|---|---|---|
| Source | Oracle Database | Operational data source and batch control repository. |
| Export | PL/SQL, SQL, Bash | Controlled extraction from Oracle. |
| Storage | Hadoop HDFS | Distributed data lake storage. |
| SQL | Apache Hive | External query layer over HDFS. |
| Processing | Apache Spark / PySpark | Distributed transformation and analytics. |
| Orchestration | Apache Airflow | Pipeline scheduling and workflow execution. |
| Monitoring | Python, Bash | Health checks and operational reporting. |
| API | FastAPI | REST integration layer. |
| UI | Swagger, HTML Dashboard | API documentation and operational dashboard. |
| Automation | Bash | Bootstrap and local platform execution. |

## Technology Rationale

### Oracle Database

Oracle represents the operational source system and provides a realistic foundation for enterprise batch extraction.

### Hadoop HDFS

HDFS provides durable distributed storage for landing, curated and analytical data.

### Hive

Hive exposes HDFS data through SQL-compatible external tables and supports analytical inspection.

### Spark

Spark is the distributed compute engine responsible for transformations, aggregations, incremental processing and analytical datasets.

### Airflow

Airflow provides workflow orchestration and execution visibility across the complete pipeline.

### FastAPI

FastAPI provides a lightweight and modern integration layer for exposing curated datasets and monitoring outputs.

### Bootstrap Scripts

The bootstrap layer standardizes local startup and validation procedures for repeatable execution.
