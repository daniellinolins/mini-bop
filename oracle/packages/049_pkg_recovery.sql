CREATE OR REPLACE PACKAGE pkg_recovery AS

    FUNCTION restart_rejected_trades(
        p_source_batch_id IN NUMBER DEFAULT NULL,
        p_use_bulk        IN VARCHAR2 DEFAULT 'Y'
    ) RETURN NUMBER;

    FUNCTION replay_batch(
        p_source_batch_id IN NUMBER,
        p_use_bulk        IN VARCHAR2 DEFAULT 'Y'
    ) RETURN NUMBER;

    FUNCTION get_latest_failed_batch RETURN NUMBER;

END pkg_recovery;
/

CREATE OR REPLACE PACKAGE BODY pkg_recovery AS

    c_module CONSTANT VARCHAR2(100) := 'PKG_RECOVERY';

    FUNCTION bool_yes(p_value VARCHAR2) RETURN BOOLEAN IS
    BEGIN
        RETURN NVL(UPPER(TRIM(p_value)), 'Y') IN ('Y', 'YES', 'TRUE', '1');
    END bool_yes;

    FUNCTION get_latest_failed_batch RETURN NUMBER IS
        v_batch_id etl_batch.batch_id%TYPE;
    BEGIN
        SELECT batch_id
          INTO v_batch_id
          FROM etl_batch
         WHERE status IN ('FAILED', 'ERROR')
         ORDER BY started_at DESC, batch_id DESC
         FETCH FIRST 1 ROWS ONLY;

        RETURN v_batch_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_latest_failed_batch;

    PROCEDURE attach_recovery_rows(
        p_new_batch_id    IN NUMBER,
        p_source_batch_id IN NUMBER DEFAULT NULL,
        p_mode            IN VARCHAR2
    ) IS
        v_rows NUMBER;
    BEGIN
        IF p_mode = 'REJECTED_ONLY' THEN
            UPDATE stg_trade_raw
               SET batch_id = p_new_batch_id,
                   processing_status = 'NEW',
                   error_count = 0,
                   processed_at = NULL
             WHERE processing_status = 'REJECTED'
               AND (p_source_batch_id IS NULL OR batch_id = p_source_batch_id);

        ELSIF p_mode = 'REPLAY_BATCH' THEN
            UPDATE stg_trade_raw
               SET batch_id = p_new_batch_id,
                   processing_status = 'NEW',
                   error_count = 0,
                   processed_at = NULL
             WHERE batch_id = p_source_batch_id
               AND processing_status IN ('NEW', 'VALIDATED', 'PROCESSED', 'REJECTED');
        END IF;

        v_rows := SQL%ROWCOUNT;

        pkg_log.info(
            p_new_batch_id,
            c_module,
            'Recovery rows attached. mode=' || p_mode || ', rows=' || v_rows ||
            ', source_batch_id=' || NVL(TO_CHAR(p_source_batch_id), 'ALL')
        );
    END attach_recovery_rows;

    FUNCTION count_processed_rows(p_batch_id IN NUMBER) RETURN NUMBER IS
        v_rows NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_rows
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND processing_status = 'PROCESSED';

        RETURN v_rows;
    END count_processed_rows;

    FUNCTION execute_recovery_pipeline(
        p_batch_id IN NUMBER,
        p_use_bulk IN VARCHAR2
    ) RETURN NUMBER IS
        v_loaded_rows NUMBER := 0;
        v_start_tick  NUMBER;
        v_elapsed_ms  NUMBER;
    BEGIN
        v_start_tick := DBMS_UTILITY.GET_TIME;

        pkg_trade_validate.validate_batch(p_batch_id);

        IF bool_yes(p_use_bulk) THEN
            v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(p_batch_id);
        ELSE
            pkg_trade_load.load_batch(p_batch_id);
            v_loaded_rows := count_processed_rows(p_batch_id);
        END IF;

        v_elapsed_ms := ROUND((DBMS_UTILITY.GET_TIME - v_start_tick) * 10);

        pkg_log.info(
            p_batch_id,
            c_module,
            'Recovery pipeline finished. loaded_rows=' || v_loaded_rows ||
            ', elapsed_ms=' || v_elapsed_ms ||
            ', use_bulk=' || NVL(UPPER(TRIM(p_use_bulk)), 'Y')
        );

        pkg_log.end_batch(p_batch_id, 'SUCCESS');
        COMMIT;

        RETURN p_batch_id;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_log.error(p_batch_id, c_module, 'Recovery pipeline failed: ' || SQLERRM);
            pkg_log.end_batch(p_batch_id, 'FAILED');
            COMMIT;
            RAISE;
    END execute_recovery_pipeline;

    FUNCTION restart_rejected_trades(
        p_source_batch_id IN NUMBER DEFAULT NULL,
        p_use_bulk        IN VARCHAR2 DEFAULT 'Y'
    ) RETURN NUMBER IS
        v_batch_id NUMBER;
    BEGIN
        v_batch_id := pkg_log.start_batch(
            p_batch_name    => 'RECOVERY_REJECTED_TRADES',
            p_source_system => 'MINI_BOP',
            p_file_name     => 'restart_rejected_trades'
        );

        pkg_log.info(
            v_batch_id,
            c_module,
            'Restart rejected trades started. source_batch_id=' || NVL(TO_CHAR(p_source_batch_id), 'ALL')
        );

        attach_recovery_rows(
            p_new_batch_id    => v_batch_id,
            p_source_batch_id => p_source_batch_id,
            p_mode            => 'REJECTED_ONLY'
        );

        RETURN execute_recovery_pipeline(v_batch_id, p_use_bulk);
    END restart_rejected_trades;

    FUNCTION replay_batch(
        p_source_batch_id IN NUMBER,
        p_use_bulk        IN VARCHAR2 DEFAULT 'Y'
    ) RETURN NUMBER IS
        v_batch_id NUMBER;
    BEGIN
        IF p_source_batch_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20013, 'p_source_batch_id is required for replay_batch');
        END IF;

        v_batch_id := pkg_log.start_batch(
            p_batch_name    => 'RECOVERY_REPLAY_BATCH',
            p_source_system => 'MINI_BOP',
            p_file_name     => 'replay_batch_' || p_source_batch_id
        );

        pkg_log.info(v_batch_id, c_module, 'Replay batch started. source_batch_id=' || p_source_batch_id);

        attach_recovery_rows(
            p_new_batch_id    => v_batch_id,
            p_source_batch_id => p_source_batch_id,
            p_mode            => 'REPLAY_BATCH'
        );

        RETURN execute_recovery_pipeline(v_batch_id, p_use_bulk);
    END replay_batch;

END pkg_recovery;
/
