CREATE OR REPLACE PACKAGE pkg_data_quality AS

    FUNCTION run_trade_dq(
        p_source_batch_id NUMBER DEFAULT NULL
    ) RETURN NUMBER;

END pkg_data_quality;
/

CREATE OR REPLACE PACKAGE BODY pkg_data_quality AS

    FUNCTION next_result_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(result_id), 0) + 1
          INTO v_id
          FROM dq_result;

        RETURN v_id;
    END next_result_id;

    FUNCTION latest_trade_batch RETURN NUMBER IS
        v_batch_id NUMBER;
    BEGIN
        SELECT MAX(batch_id)
          INTO v_batch_id
          FROM etl_batch
         WHERE batch_name IN (
             'OBSERVABILITY_TRADE_PIPELINE',
             'SCHEDULED_TRADE_PIPELINE',
             'PARALLEL_TRADE_PIPELINE',
             'TRADE_BULK_LOAD_TEST',
             'TRADE_EVENT_TEST',
             'TRADE_LOAD_TEST',
             'RECOVERY_BASE_PIPELINE',
             'RECOVERY_REJECTED_TRADES'
         );

        RETURN v_batch_id;
    END latest_trade_batch;

    PROCEDURE save_result(
        p_dq_batch_id     NUMBER,
        p_source_batch_id NUMBER,
        p_rule_code       VARCHAR2,
        p_total_rows      NUMBER,
        p_failed_rows     NUMBER
    ) IS
        v_rule          dq_rule%ROWTYPE;
        v_result_id     NUMBER;
        v_passed_rows   NUMBER;
        v_quality_score NUMBER;
        v_status        VARCHAR2(20);
    BEGIN
        SELECT *
          INTO v_rule
          FROM dq_rule
         WHERE rule_code = p_rule_code
           AND active_flag = 'Y';

        v_result_id := next_result_id;
        v_passed_rows := GREATEST(NVL(p_total_rows, 0) - NVL(p_failed_rows, 0), 0);

        IF NVL(p_total_rows, 0) = 0 THEN
            v_quality_score := 100;
        ELSE
            v_quality_score := ROUND((v_passed_rows / p_total_rows) * 100, 4);
        END IF;

        IF NVL(p_failed_rows, 0) = 0 THEN
            v_status := 'PASS';
        ELSIF v_rule.severity IN ('CRITICAL', 'ERROR') THEN
            v_status := 'FAIL';
        ELSE
            v_status := 'WARNING';
        END IF;

        INSERT INTO dq_result (
            result_id,
            dq_batch_id,
            source_batch_id,
            rule_id,
            rule_code,
            severity,
            target_table,
            target_column,
            total_rows,
            failed_rows,
            passed_rows,
            quality_score,
            result_status,
            created_at
        ) VALUES (
            v_result_id,
            p_dq_batch_id,
            p_source_batch_id,
            v_rule.rule_id,
            v_rule.rule_code,
            v_rule.severity,
            v_rule.target_table,
            v_rule.target_column,
            NVL(p_total_rows, 0),
            NVL(p_failed_rows, 0),
            v_passed_rows,
            v_quality_score,
            v_status,
            SYSTIMESTAMP
        );

        pkg_log.info(
            p_dq_batch_id,
            'PKG_DATA_QUALITY',
            'DQ_RESULT|' || p_rule_code || '|status=' || v_status || '|failed=' || NVL(p_failed_rows, 0) || '|score=' || v_quality_score
        );
    END save_result;

    FUNCTION run_trade_dq(
        p_source_batch_id NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        v_dq_batch_id     NUMBER;
        v_source_batch_id NUMBER;
        v_total           NUMBER;
        v_failed          NUMBER;
        v_fail_rules      NUMBER;
        v_warning_rules   NUMBER;
        v_final_status    VARCHAR2(20);
    BEGIN
        v_source_batch_id := NVL(p_source_batch_id, latest_trade_batch);

        v_dq_batch_id := pkg_log.start_batch(
            p_batch_name    => 'DATA_QUALITY_CHECK',
            p_source_system => 'MINI_BOP',
            p_file_name     => NULL
        );

        pkg_log.info(v_dq_batch_id, 'PKG_DATA_QUALITY', 'Data quality check started. source_batch_id=' || NVL(TO_CHAR(v_source_batch_id), 'NULL'));

        DELETE FROM dq_result
         WHERE dq_batch_id = v_dq_batch_id;

        SELECT COUNT(*)
          INTO v_total
          FROM stg_trade_raw
         WHERE batch_id = v_source_batch_id;

        SELECT COUNT(*)
          INTO v_failed
          FROM stg_trade_raw
         WHERE batch_id = v_source_batch_id
           AND external_trade_id IS NULL;
        save_result(v_dq_batch_id, v_source_batch_id, 'STG_REQUIRED_EXTERNAL_ID', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_failed
          FROM stg_trade_raw
         WHERE batch_id = v_source_batch_id
           AND processing_status NOT IN ('NEW', 'VALIDATED', 'PROCESSED', 'REJECTED');
        save_result(v_dq_batch_id, v_source_batch_id, 'STG_VALID_PROCESSING_STATUS', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_failed
          FROM stg_trade_raw s
         WHERE s.batch_id = v_source_batch_id
           AND s.processing_status = 'REJECTED'
           AND NOT EXISTS (
               SELECT 1
                 FROM stg_trade_error e
                WHERE e.stg_trade_id = s.stg_trade_id
           );
        save_result(v_dq_batch_id, v_source_batch_id, 'REJECTED_HAS_ERROR_DETAIL', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_total
          FROM stg_trade_raw
         WHERE batch_id = v_source_batch_id
           AND processing_status = 'PROCESSED';

        SELECT COUNT(*)
          INTO v_failed
          FROM stg_trade_raw s
         WHERE s.batch_id = v_source_batch_id
           AND s.processing_status = 'PROCESSED'
           AND NOT EXISTS (
               SELECT 1
                 FROM trade t
                WHERE t.external_trade_id = s.external_trade_id
                  AND t.source_system = s.source_system
           );
        save_result(v_dq_batch_id, v_source_batch_id, 'PROCESSED_HAS_TRADE', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_total
          FROM trade;

        SELECT COUNT(*)
          INTO v_failed
          FROM trade
         WHERE NVL(notional_amount, 0) <= 0;
        save_result(v_dq_batch_id, v_source_batch_id, 'TRADE_POSITIVE_NOTIONAL', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_total
          FROM trade;

        SELECT COUNT(*)
          INTO v_failed
          FROM trade t
         WHERE NOT EXISTS (
               SELECT 1
                 FROM trade_event e
                WHERE e.trade_id = t.trade_id
           );
        save_result(v_dq_batch_id, v_source_batch_id, 'TRADE_HAS_EVENT', v_total, v_failed);

        SELECT COUNT(*)
          INTO v_fail_rules
          FROM dq_result
         WHERE dq_batch_id = v_dq_batch_id
           AND result_status = 'FAIL';

        SELECT COUNT(*)
          INTO v_warning_rules
          FROM dq_result
         WHERE dq_batch_id = v_dq_batch_id
           AND result_status = 'WARNING';

        IF v_fail_rules > 0 THEN
            v_final_status := 'FAILED';
        ELSE
            v_final_status := 'SUCCESS';
        END IF;

        pkg_log.info(v_dq_batch_id, 'PKG_DATA_QUALITY', 'Data quality check finished. fail_rules=' || v_fail_rules || ', warning_rules=' || v_warning_rules);
        pkg_log.end_batch(v_dq_batch_id, v_final_status);

        COMMIT;
        RETURN v_dq_batch_id;

    EXCEPTION
        WHEN OTHERS THEN
            pkg_log.error(v_dq_batch_id, 'PKG_DATA_QUALITY', SQLERRM);
            IF v_dq_batch_id IS NOT NULL THEN
                pkg_log.end_batch(v_dq_batch_id, 'FAILED');
            END IF;
            RAISE;
    END run_trade_dq;

END pkg_data_quality;
/
