PROMPT ===========================================
PROMPT MINI BOP - PHASE 18
PROMPT ORACLE TO HADOOP EXPORT ENGINE DDL
PROMPT ===========================================

BEGIN
    EXECUTE IMMEDIATE '
        CREATE TABLE export_job (
            export_job_id      NUMBER          NOT NULL,
            export_name        VARCHAR2(100)   NOT NULL,
            source_batch_id    NUMBER,
            target_system      VARCHAR2(50)    NOT NULL,
            export_format      VARCHAR2(20)    NOT NULL,
            export_status      VARCHAR2(20)    NOT NULL,
            output_directory   VARCHAR2(100)   NOT NULL,
            hdfs_target_path   VARCHAR2(500),
            started_at         TIMESTAMP       NOT NULL,
            ended_at           TIMESTAMP,
            total_rows         NUMBER          DEFAULT 0 NOT NULL,
            exported_rows      NUMBER          DEFAULT 0 NOT NULL,
            rejected_rows      NUMBER          DEFAULT 0 NOT NULL,
            created_by         VARCHAR2(100)   NOT NULL,
            CONSTRAINT pk_export_job PRIMARY KEY (export_job_id),
            CONSTRAINT ck_export_job_status CHECK (export_status IN (''RUNNING'',''SUCCESS'',''FAILED'')),
            CONSTRAINT ck_export_job_format CHECK (export_format IN (''CSV'',''PARQUET'',''ORC''))
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
        CREATE TABLE export_file (
            export_file_id     NUMBER          NOT NULL,
            export_job_id      NUMBER          NOT NULL,
            file_role          VARCHAR2(30)    NOT NULL,
            file_name          VARCHAR2(255)   NOT NULL,
            file_path          VARCHAR2(1000),
            hdfs_path          VARCHAR2(1000),
            row_count          NUMBER          DEFAULT 0 NOT NULL,
            file_status        VARCHAR2(20)    NOT NULL,
            created_at         TIMESTAMP       NOT NULL,
            CONSTRAINT pk_export_file PRIMARY KEY (export_file_id),
            CONSTRAINT fk_export_file_job FOREIGN KEY (export_job_id) REFERENCES export_job(export_job_id),
            CONSTRAINT ck_export_file_status CHECK (file_status IN (''CREATED'',''UPLOADED'',''FAILED'')),
            CONSTRAINT ck_export_file_role CHECK (file_role IN (''DATA'',''MANIFEST'',''CONTROL''))
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
        CREATE TABLE export_manifest (
            manifest_id        NUMBER          NOT NULL,
            export_job_id      NUMBER          NOT NULL,
            manifest_key       VARCHAR2(100)   NOT NULL,
            manifest_value     VARCHAR2(4000),
            created_at         TIMESTAMP       NOT NULL,
            CONSTRAINT pk_export_manifest PRIMARY KEY (manifest_id),
            CONSTRAINT fk_export_manifest_job FOREIGN KEY (export_job_id) REFERENCES export_job(export_job_id)
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
    EXECUTE IMMEDIATE 'CREATE INDEX ix_export_job_status ON export_job(export_status, started_at)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_export_job_source_batch ON export_job(source_batch_id)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

BEGIN
    EXECUTE IMMEDIATE 'CREATE INDEX ix_export_file_job ON export_file(export_job_id, file_role)';
EXCEPTION WHEN OTHERS THEN IF SQLCODE != -955 THEN RAISE; END IF;
END;
/

PROMPT Creating Oracle DIRECTORY MINI_BOP_EXPORT_DIR...
PROMPT NOTE: if this path is not accessible to your Oracle server, edit it before running.
BEGIN
    EXECUTE IMMEDIATE q'[CREATE OR REPLACE DIRECTORY MINI_BOP_EXPORT_DIR AS 'F:\SSD_DEV\windows\projects\mini-bop\data\export']';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: could not create DIRECTORY MINI_BOP_EXPORT_DIR. Create it manually as SYSTEM if needed. Error=' || SQLERRM);
END;
/

BEGIN
    EXECUTE IMMEDIATE 'GRANT READ, WRITE ON DIRECTORY MINI_BOP_EXPORT_DIR TO MINI_BOP';
EXCEPTION
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('WARNING: could not grant DIRECTORY privileges. Run grant manually as SYSTEM if needed. Error=' || SQLERRM);
END;
/

COMMIT;

PROMPT Export engine tables created.
