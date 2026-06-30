CREATE OR REPLACE PACKAGE pkg_etl_log AS

    FUNCTION start_batch(
        p_batch_name    VARCHAR2,
        p_source_system VARCHAR2 DEFAULT NULL,
        p_file_name     VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE log_msg(
        p_batch_id    NUMBER,
        p_log_level   VARCHAR2,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    );

    PROCEDURE info(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    );

    PROCEDURE error(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    );

    PROCEDURE end_batch(
        p_batch_id NUMBER,
        p_status   VARCHAR2
    );

END pkg_etl_log;
/

CREATE OR REPLACE PACKAGE BODY pkg_etl_log AS

    FUNCTION start_batch(
        p_batch_name    VARCHAR2,
        p_source_system VARCHAR2 DEFAULT NULL,
        p_file_name     VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_batch_id NUMBER;
    BEGIN
        SELECT NVL(MAX(batch_id), 0) + 1
        INTO v_batch_id
        FROM etl_batch;

        INSERT INTO etl_batch (
            batch_id,
            batch_name,
            source_system,
            file_name,
            status,
            started_at,
            ended_at,
            total_rows,
            valid_rows,
            rejected_rows,
            created_by
        ) VALUES (
            v_batch_id,
            p_batch_name,
            p_source_system,
            p_file_name,
            'RUNNING',
            SYSTIMESTAMP,
            NULL,
            0,
            0,
            0,
            USER
        );

        log_msg(v_batch_id, 'INFO', 'PKG_ETL_LOG', 'Batch started');

        RETURN v_batch_id;
    END;

    PROCEDURE log_msg(
        p_batch_id    NUMBER,
        p_log_level   VARCHAR2,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
        v_log_id NUMBER;
    BEGIN
        SELECT NVL(MAX(log_id), 0) + 1
        INTO v_log_id
        FROM etl_log;

        INSERT INTO etl_log (
            log_id,
            batch_id,
            log_level,
            module_name,
            message,
            created_at
        ) VALUES (
            v_log_id,
            p_batch_id,
            UPPER(p_log_level),
            p_module_name,
            SUBSTR(p_message, 1, 4000),
            SYSTIMESTAMP
        );
    END;

    PROCEDURE info(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
    BEGIN
        log_msg(p_batch_id, 'INFO', p_module_name, p_message);
    END;

    PROCEDURE error(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
    BEGIN
        log_msg(p_batch_id, 'ERROR', p_module_name, p_message);
    END;

    PROCEDURE end_batch(
        p_batch_id NUMBER,
        p_status   VARCHAR2
    ) IS
    BEGIN
        UPDATE etl_batch
           SET status = UPPER(p_status),
               ended_at = SYSTIMESTAMP,
               total_rows = (
                   SELECT COUNT(*)
                   FROM stg_trade_raw
                   WHERE batch_id = p_batch_id
               ),
               valid_rows = (
                   SELECT COUNT(*)
                   FROM stg_trade_raw
                   WHERE batch_id = p_batch_id
                     AND processing_status = 'VALID'
               ),
               rejected_rows = (
                   SELECT COUNT(*)
                   FROM stg_trade_raw
                   WHERE batch_id = p_batch_id
                     AND processing_status = 'ERROR'
               )
         WHERE batch_id = p_batch_id;

        log_msg(p_batch_id, 'INFO', 'PKG_ETL_LOG', 'Batch finished with status ' || p_status);
    END;

END pkg_etl_log;
/