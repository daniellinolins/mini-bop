PROMPT ===========================================
PROMPT MINI BOP - PHASE 16
PROMPT AUDIT & DATA LINEAGE DDL
PROMPT ===========================================

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'AUDIT_LINEAGE_RUN';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE audit_lineage_run (
                lineage_run_id        NUMBER        NOT NULL,
                source_batch_id       NUMBER        NOT NULL,
                status                VARCHAR2(20)  NOT NULL,
                started_at            TIMESTAMP     NOT NULL,
                ended_at              TIMESTAMP,
                total_rows            NUMBER        DEFAULT 0 NOT NULL,
                complete_rows         NUMBER        DEFAULT 0 NOT NULL,
                rejected_source_rows  NUMBER        DEFAULT 0 NOT NULL,
                incomplete_rows       NUMBER        DEFAULT 0 NOT NULL,
                created_by            VARCHAR2(100) DEFAULT USER NOT NULL,
                CONSTRAINT pk_audit_lineage_run PRIMARY KEY (lineage_run_id),
                CONSTRAINT ck_audit_lineage_run_status CHECK (status IN ('RUNNING','SUCCESS','FAILED'))
            )
        ]';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'AUDIT_LINEAGE_TRADE';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE audit_lineage_trade (
                lineage_id           NUMBER         NOT NULL,
                lineage_run_id       NUMBER         NOT NULL,
                source_batch_id      NUMBER         NOT NULL,
                stg_trade_id         NUMBER         NOT NULL,
                external_trade_id    VARCHAR2(50),
                source_system        VARCHAR2(30),
                staging_status       VARCHAR2(20),
                trade_id             NUMBER,
                trade_status         VARCHAR2(20),
                event_count          NUMBER         DEFAULT 0 NOT NULL,
                lineage_status       VARCHAR2(30)   NOT NULL,
                raw_created_at       TIMESTAMP,
                processed_at         TIMESTAMP,
                trade_created_at     TIMESTAMP,
                last_event_at        TIMESTAMP,
                created_at           TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
                CONSTRAINT pk_audit_lineage_trade PRIMARY KEY (lineage_id),
                CONSTRAINT fk_lineage_trade_run FOREIGN KEY (lineage_run_id)
                    REFERENCES audit_lineage_run(lineage_run_id),
                CONSTRAINT ck_audit_lineage_status CHECK (lineage_status IN ('COMPLETE','REJECTED_SOURCE','INCOMPLETE'))
            )
        ]';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_tables WHERE table_name = 'AUDIT_LINEAGE_STEP';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE q'[
            CREATE TABLE audit_lineage_step (
                lineage_step_id      NUMBER         NOT NULL,
                lineage_id           NUMBER         NOT NULL,
                step_name            VARCHAR2(50)   NOT NULL,
                step_status          VARCHAR2(30)   NOT NULL,
                step_message         VARCHAR2(1000),
                step_timestamp       TIMESTAMP      DEFAULT SYSTIMESTAMP NOT NULL,
                CONSTRAINT pk_audit_lineage_step PRIMARY KEY (lineage_step_id),
                CONSTRAINT fk_lineage_step_trade FOREIGN KEY (lineage_id)
                    REFERENCES audit_lineage_trade(lineage_id)
            )
        ]';
    END IF;
END;
/

PROMPT Creating indexes...
DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IX_LINEAGE_TRADE_RUN';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX ix_lineage_trade_run ON audit_lineage_trade(lineage_run_id)';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IX_LINEAGE_TRADE_STG';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX ix_lineage_trade_stg ON audit_lineage_trade(source_batch_id, stg_trade_id)';
    END IF;
END;
/

DECLARE
    v_count NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_count FROM user_indexes WHERE index_name = 'IX_LINEAGE_STEP_LINEAGE';
    IF v_count = 0 THEN
        EXECUTE IMMEDIATE 'CREATE INDEX ix_lineage_step_lineage ON audit_lineage_step(lineage_id, step_name)';
    END IF;
END;
/

PROMPT Audit lineage tables created.
