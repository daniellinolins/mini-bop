CREATE OR REPLACE PACKAGE pkg_log AS

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

END pkg_log;
/

CREATE OR REPLACE PACKAGE BODY pkg_log AS

    FUNCTION next_batch_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(batch_id), 0) + 1
          INTO v_id
          FROM etl_batch;

        RETURN v_id;
    END next_batch_id;

    FUNCTION next_log_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(log_id), 0) + 1
          INTO v_id
          FROM etl_log;

        RETURN v_id;
    END next_log_id;

    FUNCTION start_batch(
        p_batch_name    VARCHAR2,
        p_source_system VARCHAR2 DEFAULT NULL,
        p_file_name     VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_batch_id NUMBER;
    BEGIN
        v_batch_id := next_batch_id;

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

        log_msg(v_batch_id, 'INFO', 'PKG_LOG', 'Batch started');

        RETURN v_batch_id;
    END start_batch;

    PROCEDURE log_msg(
        p_batch_id    NUMBER,
        p_log_level   VARCHAR2,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
        v_log_id NUMBER;
    BEGIN
        v_log_id := next_log_id;

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
    END log_msg;

    PROCEDURE info(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
    BEGIN
        log_msg(p_batch_id, 'INFO', p_module_name, p_message);
    END info;

    PROCEDURE error(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_message     VARCHAR2
    ) IS
    BEGIN
        log_msg(p_batch_id, 'ERROR', p_module_name, p_message);
    END error;

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
                      AND processing_status = 'VALIDATED'
               ),
               rejected_rows = (
                   SELECT COUNT(*)
                     FROM stg_trade_raw
                    WHERE batch_id = p_batch_id
                      AND processing_status = 'REJECTED'
               )
         WHERE batch_id = p_batch_id;

        log_msg(p_batch_id, 'INFO', 'PKG_LOG', 'Batch finished with status ' || UPPER(p_status));
    END end_batch;

END pkg_log;
/
