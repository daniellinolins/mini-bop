PROMPT ===========================================
PROMPT MINI BOP - PHASE 17
PROMPT CONFIGURATION DRIVEN PIPELINE DDL
PROMPT ===========================================

BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE pipeline_config (
            config_id              NUMBER NOT NULL,
            pipeline_code          VARCHAR2(100) NOT NULL,
            pipeline_name          VARCHAR2(200) NOT NULL,
            source_system          VARCHAR2(30) DEFAULT ''MUREX_SIM'' NOT NULL,
            is_active              CHAR(1) DEFAULT ''Y'' NOT NULL,
            use_bulk               CHAR(1) DEFAULT ''Y'' NOT NULL,
            use_parallel           CHAR(1) DEFAULT ''N'' NOT NULL,
            parallel_level         NUMBER DEFAULT 4 NOT NULL,
            bulk_limit             NUMBER DEFAULT 1000 NOT NULL,
            run_reconciliation     CHAR(1) DEFAULT ''Y'' NOT NULL,
            run_data_quality       CHAR(1) DEFAULT ''Y'' NOT NULL,
            run_metadata_rules     CHAR(1) DEFAULT ''Y'' NOT NULL,
            run_lineage            CHAR(1) DEFAULT ''Y'' NOT NULL,
            metadata_rule_group    VARCHAR2(100) DEFAULT ''TRADE_STAGING_DQ'',
            scheduler_job_name     VARCHAR2(128),
            scheduler_hour         NUMBER DEFAULT 2,
            created_at             TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
            updated_at             TIMESTAMP,
            CONSTRAINT pk_pipeline_config PRIMARY KEY (config_id),
            CONSTRAINT uk_pipeline_config_code UNIQUE (pipeline_code),
            CONSTRAINT ck_pipeline_config_active CHECK (is_active IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_bulk CHECK (use_bulk IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_parallel CHECK (use_parallel IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_recon CHECK (run_reconciliation IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_dq CHECK (run_data_quality IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_md CHECK (run_metadata_rules IN (''Y'',''N'')),
            CONSTRAINT ck_pipeline_config_lineage CHECK (run_lineage IN (''Y'',''N''))
        )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE pipeline_config_run (
            config_run_id          NUMBER NOT NULL,
            pipeline_code          VARCHAR2(100) NOT NULL,
            source_batch_id        NUMBER,
            orchestration_batch_id NUMBER,
            reconciliation_batch_id NUMBER,
            dq_batch_id            NUMBER,
            metadata_execution_id  NUMBER,
            lineage_run_id         NUMBER,
            status                 VARCHAR2(30) NOT NULL,
            loaded_rows            NUMBER DEFAULT 0 NOT NULL,
            elapsed_ms             NUMBER DEFAULT 0 NOT NULL,
            error_message          VARCHAR2(4000),
            started_at             TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
            ended_at               TIMESTAMP,
            created_by             VARCHAR2(100) DEFAULT USER NOT NULL,
            CONSTRAINT pk_pipeline_config_run PRIMARY KEY (config_run_id)
        )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN
            RAISE;
        END IF;
END;
/

PROMPT Creating indexes...
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_pipeline_config_run_code ON pipeline_config_run(pipeline_code, started_at)';
EXCEPTION
    WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_pipeline_config_run_status ON pipeline_config_run(status, started_at)';
EXCEPTION
    WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

PROMPT Seeding pipeline configuration...
MERGE INTO pipeline_config tgt
USING (
    SELECT 1 AS config_id,
           'DAILY_TRADE_PIPELINE' AS pipeline_code,
           'Daily Trade Processing Pipeline' AS pipeline_name,
           'MUREX_SIM' AS source_system,
           'Y' AS is_active,
           'Y' AS use_bulk,
           'N' AS use_parallel,
           4 AS parallel_level,
           1000 AS bulk_limit,
           'Y' AS run_reconciliation,
           'Y' AS run_data_quality,
           'Y' AS run_metadata_rules,
           'Y' AS run_lineage,
           'TRADE_STAGING_DQ' AS metadata_rule_group,
           'MINI_BOP_DAILY_TRADE_PIPELINE' AS scheduler_job_name,
           2 AS scheduler_hour
    FROM dual
) src
ON (tgt.pipeline_code = src.pipeline_code)
WHEN MATCHED THEN UPDATE SET
    tgt.pipeline_name       = src.pipeline_name,
    tgt.source_system       = src.source_system,
    tgt.is_active           = src.is_active,
    tgt.use_bulk            = src.use_bulk,
    tgt.use_parallel        = src.use_parallel,
    tgt.parallel_level      = src.parallel_level,
    tgt.bulk_limit          = src.bulk_limit,
    tgt.run_reconciliation  = src.run_reconciliation,
    tgt.run_data_quality    = src.run_data_quality,
    tgt.run_metadata_rules  = src.run_metadata_rules,
    tgt.run_lineage         = src.run_lineage,
    tgt.metadata_rule_group = src.metadata_rule_group,
    tgt.scheduler_job_name  = src.scheduler_job_name,
    tgt.scheduler_hour      = src.scheduler_hour,
    tgt.updated_at          = SYSTIMESTAMP
WHEN NOT MATCHED THEN INSERT (
    config_id, pipeline_code, pipeline_name, source_system, is_active,
    use_bulk, use_parallel, parallel_level, bulk_limit,
    run_reconciliation, run_data_quality, run_metadata_rules, run_lineage,
    metadata_rule_group, scheduler_job_name, scheduler_hour
) VALUES (
    src.config_id, src.pipeline_code, src.pipeline_name, src.source_system, src.is_active,
    src.use_bulk, src.use_parallel, src.parallel_level, src.bulk_limit,
    src.run_reconciliation, src.run_data_quality, src.run_metadata_rules, src.run_lineage,
    src.metadata_rule_group, src.scheduler_job_name, src.scheduler_hour
);

COMMIT;

PROMPT Configuration driven pipeline tables created.
