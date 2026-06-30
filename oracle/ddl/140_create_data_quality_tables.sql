PROMPT ===========================================
PROMPT MINI BOP - PHASE 14
PROMPT DATA QUALITY FRAMEWORK DDL
PROMPT ===========================================

DECLARE
    PROCEDURE exec_ddl(p_sql CLOB) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -955 THEN
                RAISE;
            END IF;
    END;
BEGIN
    exec_ddl(q'[
        CREATE TABLE dq_rule (
            rule_id        NUMBER        NOT NULL,
            rule_code      VARCHAR2(100) NOT NULL,
            rule_name      VARCHAR2(255) NOT NULL,
            target_table   VARCHAR2(100) NOT NULL,
            target_column  VARCHAR2(100),
            severity       VARCHAR2(20)  NOT NULL,
            rule_type      VARCHAR2(50)  NOT NULL,
            active_flag    CHAR(1)       DEFAULT 'Y' NOT NULL,
            created_at     TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
            CONSTRAINT pk_dq_rule PRIMARY KEY (rule_id),
            CONSTRAINT uk_dq_rule_code UNIQUE (rule_code),
            CONSTRAINT ck_dq_rule_severity CHECK (severity IN ('INFO','WARNING','ERROR','CRITICAL')),
            CONSTRAINT ck_dq_rule_active CHECK (active_flag IN ('Y','N'))
        )
    ]');

    exec_ddl(q'[
        CREATE TABLE dq_result (
            result_id       NUMBER        NOT NULL,
            dq_batch_id     NUMBER        NOT NULL,
            source_batch_id NUMBER,
            rule_id         NUMBER        NOT NULL,
            rule_code       VARCHAR2(100) NOT NULL,
            severity        VARCHAR2(20)  NOT NULL,
            target_table    VARCHAR2(100) NOT NULL,
            target_column   VARCHAR2(100),
            total_rows      NUMBER        DEFAULT 0 NOT NULL,
            failed_rows     NUMBER        DEFAULT 0 NOT NULL,
            passed_rows     NUMBER        DEFAULT 0 NOT NULL,
            quality_score   NUMBER(10,4)  DEFAULT 100 NOT NULL,
            result_status   VARCHAR2(20)  NOT NULL,
            created_at      TIMESTAMP     DEFAULT SYSTIMESTAMP NOT NULL,
            CONSTRAINT pk_dq_result PRIMARY KEY (result_id),
            CONSTRAINT fk_dq_result_rule FOREIGN KEY (rule_id) REFERENCES dq_rule(rule_id),
            CONSTRAINT ck_dq_result_status CHECK (result_status IN ('PASS','WARNING','FAIL'))
        )
    ]');
END;
/

PROMPT Creating indexes...
DECLARE
    PROCEDURE exec_ddl(p_sql CLOB) IS
    BEGIN
        EXECUTE IMMEDIATE p_sql;
    EXCEPTION
        WHEN OTHERS THEN
            IF SQLCODE != -955 THEN
                RAISE;
            END IF;
    END;
BEGIN
    exec_ddl('CREATE INDEX ix_dq_result_batch ON dq_result(dq_batch_id)');
    exec_ddl('CREATE INDEX ix_dq_result_source_batch ON dq_result(source_batch_id)');
    exec_ddl('CREATE INDEX ix_dq_result_rule ON dq_result(rule_id)');
END;
/

PROMPT Seeding data quality rules...
MERGE INTO dq_rule r
USING (
    SELECT 1 rule_id, 'STG_REQUIRED_EXTERNAL_ID' rule_code, 'External trade id must be populated' rule_name, 'STG_TRADE_RAW' target_table, 'EXTERNAL_TRADE_ID' target_column, 'ERROR' severity, 'COMPLETENESS' rule_type FROM dual UNION ALL
    SELECT 2, 'STG_VALID_PROCESSING_STATUS', 'Staging processing status must be valid', 'STG_TRADE_RAW', 'PROCESSING_STATUS', 'CRITICAL', 'VALIDITY' FROM dual UNION ALL
    SELECT 3, 'REJECTED_HAS_ERROR_DETAIL', 'Rejected staging rows must have error details', 'STG_TRADE_RAW', 'PROCESSING_STATUS', 'ERROR', 'CONSISTENCY' FROM dual UNION ALL
    SELECT 4, 'PROCESSED_HAS_TRADE', 'Processed staging rows must exist in TRADE', 'TRADE', 'EXTERNAL_TRADE_ID', 'CRITICAL', 'RECONCILIATION' FROM dual UNION ALL
    SELECT 5, 'TRADE_POSITIVE_NOTIONAL', 'Loaded trades must have positive notional amount', 'TRADE', 'NOTIONAL_AMOUNT', 'CRITICAL', 'ACCURACY' FROM dual UNION ALL
    SELECT 6, 'TRADE_HAS_EVENT', 'Loaded trades must have at least one trade event', 'TRADE_EVENT', 'TRADE_ID', 'WARNING', 'TRACEABILITY' FROM dual
) s
ON (r.rule_code = s.rule_code)
WHEN MATCHED THEN UPDATE SET
    r.rule_name     = s.rule_name,
    r.target_table  = s.target_table,
    r.target_column = s.target_column,
    r.severity      = s.severity,
    r.rule_type     = s.rule_type,
    r.active_flag   = 'Y'
WHEN NOT MATCHED THEN INSERT (
    rule_id, rule_code, rule_name, target_table, target_column, severity, rule_type, active_flag, created_at
) VALUES (
    s.rule_id, s.rule_code, s.rule_name, s.target_table, s.target_column, s.severity, s.rule_type, 'Y', SYSTIMESTAMP
);

COMMIT;

PROMPT Data quality framework tables created.
