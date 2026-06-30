PROMPT ===========================================
PROMPT MINI BOP - PHASE 15
PROMPT METADATA DRIVEN ENGINE DDL
PROMPT ===========================================

BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE md_rule_group (
        rule_group_id      NUMBER NOT NULL,
        rule_group_code    VARCHAR2(100) NOT NULL,
        rule_group_name    VARCHAR2(200) NOT NULL,
        description        VARCHAR2(1000),
        active_flag        CHAR(1) DEFAULT ''Y'' NOT NULL,
        created_at         TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT pk_md_rule_group PRIMARY KEY (rule_group_id),
        CONSTRAINT uk_md_rule_group_code UNIQUE (rule_group_code),
        CONSTRAINT ck_md_rule_group_active CHECK (active_flag IN (''Y'',''N''))
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE md_rule_definition (
        rule_id            NUMBER NOT NULL,
        rule_group_id      NUMBER NOT NULL,
        rule_code          VARCHAR2(100) NOT NULL,
        rule_name          VARCHAR2(200) NOT NULL,
        target_table       VARCHAR2(100) NOT NULL,
        target_column      VARCHAR2(100),
        rule_type          VARCHAR2(50) NOT NULL,
        severity           VARCHAR2(20) NOT NULL,
        failure_condition  VARCHAR2(4000) NOT NULL,
        active_flag        CHAR(1) DEFAULT ''Y'' NOT NULL,
        execution_order    NUMBER DEFAULT 100 NOT NULL,
        created_at         TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT pk_md_rule_definition PRIMARY KEY (rule_id),
        CONSTRAINT uk_md_rule_definition_code UNIQUE (rule_code),
        CONSTRAINT fk_md_rule_group FOREIGN KEY (rule_group_id) REFERENCES md_rule_group(rule_group_id),
        CONSTRAINT ck_md_rule_active CHECK (active_flag IN (''Y'',''N'')),
        CONSTRAINT ck_md_rule_severity CHECK (severity IN (''INFO'',''WARNING'',''ERROR'',''CRITICAL''))
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE md_rule_execution (
        execution_id       NUMBER NOT NULL,
        batch_id           NUMBER NOT NULL,
        source_batch_id    NUMBER,
        rule_group_code    VARCHAR2(100) NOT NULL,
        started_at         TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
        ended_at           TIMESTAMP,
        status             VARCHAR2(20) NOT NULL,
        total_rules        NUMBER DEFAULT 0 NOT NULL,
        passed_rules       NUMBER DEFAULT 0 NOT NULL,
        warning_rules      NUMBER DEFAULT 0 NOT NULL,
        failed_rules       NUMBER DEFAULT 0 NOT NULL,
        avg_score          NUMBER(10,2),
        CONSTRAINT pk_md_rule_execution PRIMARY KEY (execution_id),
        CONSTRAINT ck_md_rule_exec_status CHECK (status IN (''RUNNING'',''SUCCESS'',''FAILED''))
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE TABLE md_rule_execution_result (
        result_id          NUMBER NOT NULL,
        execution_id       NUMBER NOT NULL,
        batch_id           NUMBER NOT NULL,
        rule_id            NUMBER NOT NULL,
        rule_code          VARCHAR2(100) NOT NULL,
        severity           VARCHAR2(20) NOT NULL,
        total_rows         NUMBER DEFAULT 0 NOT NULL,
        failed_rows        NUMBER DEFAULT 0 NOT NULL,
        passed_rows        NUMBER DEFAULT 0 NOT NULL,
        quality_score      NUMBER(10,2),
        result_status      VARCHAR2(20) NOT NULL,
        executed_sql       CLOB,
        error_message      VARCHAR2(4000),
        created_at         TIMESTAMP DEFAULT SYSTIMESTAMP NOT NULL,
        CONSTRAINT pk_md_rule_execution_result PRIMARY KEY (result_id),
        CONSTRAINT fk_md_rule_exec_result_exec FOREIGN KEY (execution_id) REFERENCES md_rule_execution(execution_id),
        CONSTRAINT fk_md_rule_exec_result_rule FOREIGN KEY (rule_id) REFERENCES md_rule_definition(rule_id),
        CONSTRAINT ck_md_rule_result_status CHECK (result_status IN (''PASS'',''WARNING'',''FAIL'',''ERROR''))
    )';
EXCEPTION
    WHEN OTHERS THEN
        IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

PROMPT Creating indexes...
BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_md_rule_def_group ON md_rule_definition(rule_group_id, active_flag, execution_order)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_md_rule_exec_batch ON md_rule_execution(batch_id, source_batch_id)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_md_rule_result_exec ON md_rule_execution_result(execution_id, result_status)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

PROMPT Seeding metadata rule groups...
MERGE INTO md_rule_group tgt
USING (
    SELECT 1 rule_group_id, 'TRADE_STAGING_DQ' rule_group_code, 'Trade Staging Data Quality' rule_group_name, 'Metadata driven rules for STG_TRADE_RAW and loaded TRADE consistency' description FROM dual
) src
ON (tgt.rule_group_code = src.rule_group_code)
WHEN MATCHED THEN UPDATE SET
    tgt.rule_group_name = src.rule_group_name,
    tgt.description = src.description,
    tgt.active_flag = 'Y'
WHEN NOT MATCHED THEN INSERT (
    rule_group_id, rule_group_code, rule_group_name, description, active_flag, created_at
) VALUES (
    src.rule_group_id, src.rule_group_code, src.rule_group_name, src.description, 'Y', SYSTIMESTAMP
);

PROMPT Seeding metadata rules...
MERGE INTO md_rule_definition tgt
USING (
    SELECT 1 rule_id, 1 rule_group_id, 'MD_EXT_ID_REQUIRED' rule_code, 'External Trade Id is required' rule_name, 'STG_TRADE_RAW' target_table, 'EXTERNAL_TRADE_ID' target_column, 'COMPLETENESS' rule_type, 'ERROR' severity, 'external_trade_id IS NULL' failure_condition, 10 execution_order FROM dual
    UNION ALL SELECT 2, 1, 'MD_VALID_STATUS', 'Processing status must be valid', 'STG_TRADE_RAW', 'PROCESSING_STATUS', 'VALIDITY', 'CRITICAL', 'processing_status NOT IN (''NEW'',''VALIDATED'',''PROCESSED'',''REJECTED'')', 20 FROM dual
    UNION ALL SELECT 3, 1, 'MD_REJECTED_HAS_ERRORS', 'Rejected staging rows must have error details', 'STG_TRADE_RAW', 'PROCESSING_STATUS', 'CONSISTENCY', 'ERROR', 'processing_status = ''REJECTED'' AND NOT EXISTS (SELECT 1 FROM stg_trade_error e WHERE e.stg_trade_id = t.stg_trade_id)', 30 FROM dual
    UNION ALL SELECT 4, 1, 'MD_PROCESSED_HAS_TRADE', 'Processed staging rows must exist in TRADE', 'STG_TRADE_RAW', 'PROCESSING_STATUS', 'RECONCILIATION', 'CRITICAL', 'processing_status = ''PROCESSED'' AND NOT EXISTS (SELECT 1 FROM trade tr WHERE tr.external_trade_id = t.external_trade_id AND tr.source_system = t.source_system)', 40 FROM dual
    UNION ALL SELECT 5, 1, 'MD_TRADE_POSITIVE_NOTIONAL', 'Loaded trades must have positive notional amount', 'TRADE', 'NOTIONAL_AMOUNT', 'ACCURACY', 'CRITICAL', 'notional_amount IS NULL OR notional_amount <= 0', 50 FROM dual
    UNION ALL SELECT 6, 1, 'MD_TRADE_HAS_EVENT', 'Loaded trades must have at least one event', 'TRADE', 'TRADE_ID', 'TRACEABILITY', 'WARNING', 'NOT EXISTS (SELECT 1 FROM trade_event ev WHERE ev.trade_id = t.trade_id)', 60 FROM dual
) src
ON (tgt.rule_code = src.rule_code)
WHEN MATCHED THEN UPDATE SET
    tgt.rule_group_id = src.rule_group_id,
    tgt.rule_name = src.rule_name,
    tgt.target_table = src.target_table,
    tgt.target_column = src.target_column,
    tgt.rule_type = src.rule_type,
    tgt.severity = src.severity,
    tgt.failure_condition = src.failure_condition,
    tgt.active_flag = 'Y',
    tgt.execution_order = src.execution_order
WHEN NOT MATCHED THEN INSERT (
    rule_id, rule_group_id, rule_code, rule_name, target_table, target_column,
    rule_type, severity, failure_condition, active_flag, execution_order, created_at
) VALUES (
    src.rule_id, src.rule_group_id, src.rule_code, src.rule_name, src.target_table, src.target_column,
    src.rule_type, src.severity, src.failure_condition, 'Y', src.execution_order, SYSTIMESTAMP
);

COMMIT;

PROMPT Metadata driven engine tables created.
