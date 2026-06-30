CREATE OR REPLACE PACKAGE pkg_observability AS

    PROCEDURE set_context(
        p_module_name VARCHAR2,
        p_action_name VARCHAR2
    );

    PROCEDURE clear_context;

    PROCEDURE log_metric(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_metric_name VARCHAR2,
        p_metric_value NUMBER
    );

    PROCEDURE run_instrumented_pipeline(
        p_use_bulk     IN VARCHAR2 DEFAULT 'Y',
        p_batch_id     OUT NUMBER,
        p_loaded_rows  OUT NUMBER,
        p_elapsed_ms   OUT NUMBER
    );

END pkg_observability;
/

CREATE OR REPLACE PACKAGE BODY pkg_observability AS

    c_module CONSTANT VARCHAR2(100) := 'PKG_OBSERVABILITY';

    PROCEDURE set_context(
        p_module_name VARCHAR2,
        p_action_name VARCHAR2
    ) IS
    BEGIN
        DBMS_APPLICATION_INFO.SET_MODULE(
            module_name => SUBSTR(p_module_name, 1, 48),
            action_name => SUBSTR(p_action_name, 1, 32)
        );
    END set_context;

    PROCEDURE clear_context IS
    BEGIN
        DBMS_APPLICATION_INFO.SET_MODULE(NULL, NULL);
        DBMS_APPLICATION_INFO.SET_ACTION(NULL);
        DBMS_APPLICATION_INFO.SET_CLIENT_INFO(NULL);
    END clear_context;

    PROCEDURE log_metric(
        p_batch_id    NUMBER,
        p_module_name VARCHAR2,
        p_metric_name VARCHAR2,
        p_metric_value NUMBER
    ) IS
    BEGIN
        pkg_log.info(
            p_batch_id,
            p_module_name,
            'METRIC|' || p_metric_name || '=' || TO_CHAR(p_metric_value)
        );
    END log_metric;

    PROCEDURE attach_pending_rows(
        p_batch_id OUT NUMBER,
        p_attached_rows OUT NUMBER
    ) IS
    BEGIN
        p_batch_id := pkg_log.start_batch(
            p_batch_name    => 'OBSERVABILITY_TRADE_PIPELINE',
            p_source_system => 'MUREX_SIM',
            p_file_name     => 'instrumented_pipeline'
        );

        UPDATE stg_trade_raw
           SET batch_id = p_batch_id,
               error_count = 0,
               processed_at = NULL
         WHERE processing_status = 'NEW'
           AND batch_id IS NULL;

        p_attached_rows := SQL%ROWCOUNT;
        log_metric(p_batch_id, c_module, 'attached_rows', p_attached_rows);
    END attach_pending_rows;

    PROCEDURE run_instrumented_pipeline(
        p_use_bulk     IN VARCHAR2 DEFAULT 'Y',
        p_batch_id     OUT NUMBER,
        p_loaded_rows  OUT NUMBER,
        p_elapsed_ms   OUT NUMBER
    ) IS
        v_start_time       NUMBER;
        v_step_start       NUMBER;
        v_attached_rows    NUMBER;
        v_validated_rows   NUMBER;
        v_rejected_rows    NUMBER;
        v_use_bulk         VARCHAR2(1) := CASE WHEN UPPER(NVL(p_use_bulk, 'Y')) = 'Y' THEN 'Y' ELSE 'N' END;
    BEGIN
        v_start_time := DBMS_UTILITY.GET_TIME;
        p_loaded_rows := 0;
        p_elapsed_ms := 0;

        set_context(c_module, 'START_BATCH');
        attach_pending_rows(p_batch_id, v_attached_rows);

        pkg_log.info(
            p_batch_id,
            c_module,
            'Instrumented pipeline started. use_bulk=' || v_use_bulk
        );

        set_context(c_module, 'VALIDATE_TRADES');
        v_step_start := DBMS_UTILITY.GET_TIME;
        pkg_trade_validate.validate_batch(p_batch_id);
        log_metric(p_batch_id, c_module, 'validation_elapsed_ms', ROUND((DBMS_UTILITY.GET_TIME - v_step_start) * 10));

        SELECT COUNT(*)
          INTO v_validated_rows
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND processing_status = 'VALIDATED';

        SELECT COUNT(*)
          INTO v_rejected_rows
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND processing_status = 'REJECTED';

        log_metric(p_batch_id, c_module, 'validated_rows', v_validated_rows);
        log_metric(p_batch_id, c_module, 'rejected_rows', v_rejected_rows);

        IF v_use_bulk = 'Y' THEN
            set_context(c_module, 'BULK_LOAD_TRADES');
            v_step_start := DBMS_UTILITY.GET_TIME;
            p_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(p_batch_id, 1000);
            log_metric(p_batch_id, c_module, 'bulk_load_elapsed_ms', ROUND((DBMS_UTILITY.GET_TIME - v_step_start) * 10));
        ELSE
            set_context(c_module, 'ROW_LOAD_TRADES');
            v_step_start := DBMS_UTILITY.GET_TIME;
            pkg_trade_load.load_batch(p_batch_id);

            SELECT COUNT(*)
              INTO p_loaded_rows
              FROM stg_trade_raw
             WHERE batch_id = p_batch_id
               AND processing_status = 'PROCESSED';

            log_metric(p_batch_id, c_module, 'row_load_elapsed_ms', ROUND((DBMS_UTILITY.GET_TIME - v_step_start) * 10));
        END IF;

        p_elapsed_ms := ROUND((DBMS_UTILITY.GET_TIME - v_start_time) * 10);

        log_metric(p_batch_id, c_module, 'loaded_rows', p_loaded_rows);
        log_metric(p_batch_id, c_module, 'pipeline_elapsed_ms', p_elapsed_ms);

        pkg_log.info(
            p_batch_id,
            c_module,
            'Instrumented pipeline finished. loaded_rows=' || p_loaded_rows || ', elapsed_ms=' || p_elapsed_ms
        );

        set_context(c_module, 'END_BATCH');
        pkg_log.end_batch(p_batch_id, 'SUCCESS');
        clear_context;
    EXCEPTION
        WHEN OTHERS THEN
            IF p_batch_id IS NOT NULL THEN
                pkg_log.error(p_batch_id, c_module, SQLERRM);
                pkg_log.end_batch(p_batch_id, 'FAILED');
            END IF;
            clear_context;
            RAISE;
    END run_instrumented_pipeline;

END pkg_observability;
/
