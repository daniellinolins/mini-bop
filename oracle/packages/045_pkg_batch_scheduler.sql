CREATE OR REPLACE PACKAGE pkg_batch_scheduler AS

    c_daily_trade_job CONSTANT VARCHAR2(128) := 'MINI_BOP_DAILY_TRADE_PIPELINE';

    PROCEDURE run_trade_pipeline(
        p_source_system VARCHAR2 DEFAULT 'MUREX_SIM',
        p_file_name     VARCHAR2 DEFAULT 'scheduled_trade_capture.csv',
        p_use_bulk      BOOLEAN  DEFAULT TRUE
    );

    PROCEDURE create_daily_trade_job(
        p_start_time VARCHAR2 DEFAULT '02:00'
    );

    PROCEDURE drop_daily_trade_job;

    PROCEDURE run_daily_trade_job_now(
        p_use_current_session BOOLEAN DEFAULT TRUE
    );

END pkg_batch_scheduler;
/

CREATE OR REPLACE PACKAGE BODY pkg_batch_scheduler AS

    FUNCTION job_exists(p_job_name VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM user_scheduler_jobs
         WHERE job_name = UPPER(p_job_name);

        RETURN v_count > 0;
    END job_exists;

    FUNCTION hour_from_time(p_start_time VARCHAR2) RETURN PLS_INTEGER IS
    BEGIN
        RETURN TO_NUMBER(SUBSTR(TRIM(p_start_time), 1, 2));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 2;
    END hour_from_time;

    FUNCTION minute_from_time(p_start_time VARCHAR2) RETURN PLS_INTEGER IS
    BEGIN
        RETURN TO_NUMBER(SUBSTR(TRIM(p_start_time), 4, 2));
    EXCEPTION
        WHEN OTHERS THEN
            RETURN 0;
    END minute_from_time;

    PROCEDURE run_trade_pipeline(
        p_source_system VARCHAR2 DEFAULT 'MUREX_SIM',
        p_file_name     VARCHAR2 DEFAULT 'scheduled_trade_capture.csv',
        p_use_bulk      BOOLEAN  DEFAULT TRUE
    ) IS
        v_batch_id    NUMBER;
        v_loaded_rows NUMBER := 0;
        v_start_tick  NUMBER;
        v_elapsed_ms  NUMBER;
    BEGIN
        v_start_tick := DBMS_UTILITY.GET_TIME;

        v_batch_id := pkg_log.start_batch(
            p_batch_name    => 'SCHEDULED_TRADE_PIPELINE',
            p_source_system => p_source_system,
            p_file_name     => p_file_name
        );

        pkg_log.info(
            v_batch_id,
            'PKG_BATCH_SCHEDULER',
            'Scheduled trade pipeline started. use_bulk=' || CASE WHEN p_use_bulk THEN 'Y' ELSE 'N' END
        );

        UPDATE stg_trade_raw
           SET batch_id = v_batch_id,
               processing_status = 'NEW',
               error_count = 0,
               processed_at = NULL
         WHERE processing_status = 'NEW'
            OR batch_id IS NULL;

        pkg_trade_validate.validate_batch(v_batch_id);

        IF p_use_bulk THEN
            v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(
                p_batch_id => v_batch_id,
                p_limit    => 1000
            );
        ELSE
            pkg_trade_load.load_batch(
                p_batch_id => v_batch_id
            );

            SELECT COUNT(*)
              INTO v_loaded_rows
              FROM stg_trade_raw
             WHERE batch_id = v_batch_id
               AND processing_status = 'PROCESSED';
        END IF;

        v_elapsed_ms := ROUND((DBMS_UTILITY.GET_TIME - v_start_tick) * 10);

        pkg_log.info(
            v_batch_id,
            'PKG_BATCH_SCHEDULER',
            'Scheduled trade pipeline finished. loaded_rows=' || v_loaded_rows || ', elapsed_ms=' || v_elapsed_ms
        );

        pkg_log.end_batch(v_batch_id, 'SUCCESS');

        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            IF v_batch_id IS NOT NULL THEN
                pkg_log.error(
                    v_batch_id,
                    'PKG_BATCH_SCHEDULER',
                    'Scheduled trade pipeline failed: ' || SQLERRM
                );
                pkg_log.end_batch(v_batch_id, 'FAILED');
                COMMIT;
            END IF;

            RAISE;
    END run_trade_pipeline;

    PROCEDURE create_daily_trade_job(
        p_start_time VARCHAR2 DEFAULT '02:00'
    ) IS
        v_hour   PLS_INTEGER;
        v_minute PLS_INTEGER;
        v_repeat VARCHAR2(200);
    BEGIN
        v_hour   := hour_from_time(p_start_time);
        v_minute := minute_from_time(p_start_time);

        v_repeat := 'FREQ=DAILY;BYHOUR=' || v_hour || ';BYMINUTE=' || v_minute || ';BYSECOND=0';

        IF job_exists(c_daily_trade_job) THEN
            DBMS_SCHEDULER.DROP_JOB(
                job_name => c_daily_trade_job,
                force    => TRUE
            );
        END IF;

        DBMS_SCHEDULER.CREATE_JOB(
            job_name        => c_daily_trade_job,
            job_type        => 'PLSQL_BLOCK',
            job_action      => 'BEGIN pkg_batch_scheduler.run_trade_pipeline(p_source_system => ''MUREX_SIM'', p_file_name => ''scheduled_trade_capture.csv'', p_use_bulk => TRUE); END;',
            start_date      => SYSTIMESTAMP,
            repeat_interval => v_repeat,
            enabled         => FALSE,
            comments        => 'Mini BOP daily scheduled trade pipeline using validation and bulk load.'
        );

        DBMS_SCHEDULER.ENABLE(c_daily_trade_job);
    END create_daily_trade_job;

    PROCEDURE drop_daily_trade_job IS
    BEGIN
        IF job_exists(c_daily_trade_job) THEN
            DBMS_SCHEDULER.DROP_JOB(
                job_name => c_daily_trade_job,
                force    => TRUE
            );
        END IF;
    END drop_daily_trade_job;

    PROCEDURE run_daily_trade_job_now(
        p_use_current_session BOOLEAN DEFAULT TRUE
    ) IS
    BEGIN
        IF NOT job_exists(c_daily_trade_job) THEN
            create_daily_trade_job('02:00');
        END IF;

        DBMS_SCHEDULER.RUN_JOB(
            job_name            => c_daily_trade_job,
            use_current_session => p_use_current_session
        );
    END run_daily_trade_job_now;

END pkg_batch_scheduler;
/
