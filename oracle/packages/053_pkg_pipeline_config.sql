CREATE OR REPLACE PACKAGE pkg_pipeline_config AS

    FUNCTION run_configured_pipeline(
        p_pipeline_code VARCHAR2
    ) RETURN NUMBER;

    PROCEDURE set_flag(
        p_pipeline_code VARCHAR2,
        p_flag_name     VARCHAR2,
        p_flag_value    VARCHAR2
    );

    FUNCTION latest_run_id(
        p_pipeline_code VARCHAR2
    ) RETURN NUMBER;

END pkg_pipeline_config;
/

CREATE OR REPLACE PACKAGE BODY pkg_pipeline_config AS

    FUNCTION next_config_run_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(config_run_id), 0) + 1
          INTO v_id
          FROM pipeline_config_run;
        RETURN v_id;
    END next_config_run_id;

    PROCEDURE log_metric(
        p_batch_id NUMBER,
        p_name     VARCHAR2,
        p_value    NUMBER
    ) IS
    BEGIN
        pkg_log.info(
            p_batch_id,
            'PKG_PIPELINE_CONFIG',
            'CONFIG_METRIC|' || p_name || '=' || TO_CHAR(p_value)
        );
    END log_metric;

    FUNCTION latest_run_id(
        p_pipeline_code VARCHAR2
    ) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT MAX(config_run_id)
          INTO v_id
          FROM pipeline_config_run
         WHERE pipeline_code = UPPER(TRIM(p_pipeline_code));
        RETURN v_id;
    END latest_run_id;

    PROCEDURE set_flag(
        p_pipeline_code VARCHAR2,
        p_flag_name     VARCHAR2,
        p_flag_value    VARCHAR2
    ) IS
        v_sql   VARCHAR2(1000);
        v_flag  VARCHAR2(100);
        v_value VARCHAR2(1);
    BEGIN
        v_flag := LOWER(TRIM(p_flag_name));
        v_value := UPPER(TRIM(p_flag_value));

        IF v_flag NOT IN (
            'is_active', 'use_bulk', 'use_parallel',
            'run_reconciliation', 'run_data_quality',
            'run_metadata_rules', 'run_lineage'
        ) THEN
            RAISE_APPLICATION_ERROR(-20071, 'Invalid pipeline flag: ' || p_flag_name);
        END IF;

        IF v_value NOT IN ('Y','N') THEN
            RAISE_APPLICATION_ERROR(-20072, 'Flag value must be Y or N');
        END IF;

        v_sql := 'UPDATE pipeline_config SET ' || v_flag || ' = :1, updated_at = SYSTIMESTAMP WHERE pipeline_code = :2';
        EXECUTE IMMEDIATE v_sql USING v_value, UPPER(TRIM(p_pipeline_code));

        IF SQL%ROWCOUNT = 0 THEN
            RAISE_APPLICATION_ERROR(-20073, 'Pipeline config not found: ' || p_pipeline_code);
        END IF;

        COMMIT;
    END set_flag;

    FUNCTION run_configured_pipeline(
        p_pipeline_code VARCHAR2
    ) RETURN NUMBER IS
        v_cfg                   pipeline_config%ROWTYPE;
        v_config_run_id         NUMBER;
        v_orchestration_batch_id NUMBER;
        v_source_batch_id       NUMBER;
        v_recon_batch_id        NUMBER;
        v_dq_batch_id           NUMBER;
        v_metadata_execution_id NUMBER;
        v_lineage_run_id        NUMBER;
        v_loaded_rows           NUMBER := 0;
        v_attached_rows         NUMBER := 0;
        v_start                 NUMBER;
        v_elapsed               NUMBER := 0;
        v_parallel_elapsed      NUMBER := 0;
        v_error                 VARCHAR2(4000);
    BEGIN
        SELECT *
          INTO v_cfg
          FROM pipeline_config
         WHERE pipeline_code = UPPER(TRIM(p_pipeline_code));

        IF v_cfg.is_active <> 'Y' THEN
            RAISE_APPLICATION_ERROR(-20074, 'Pipeline config is inactive: ' || p_pipeline_code);
        END IF;

        v_config_run_id := next_config_run_id;

        v_orchestration_batch_id := pkg_log.start_batch(
            p_batch_name    => 'CONFIG_DRIVEN_PIPELINE',
            p_source_system => v_cfg.source_system,
            p_file_name     => v_cfg.pipeline_code
        );

        INSERT INTO pipeline_config_run (
            config_run_id,
            pipeline_code,
            orchestration_batch_id,
            status,
            started_at
        ) VALUES (
            v_config_run_id,
            v_cfg.pipeline_code,
            v_orchestration_batch_id,
            'RUNNING',
            SYSTIMESTAMP
        );

        COMMIT;

        v_start := DBMS_UTILITY.GET_TIME;

        pkg_log.info(v_orchestration_batch_id, 'PKG_PIPELINE_CONFIG',
            'Configured pipeline started. code=' || v_cfg.pipeline_code ||
            ', use_bulk=' || v_cfg.use_bulk ||
            ', use_parallel=' || v_cfg.use_parallel ||
            ', recon=' || v_cfg.run_reconciliation ||
            ', dq=' || v_cfg.run_data_quality ||
            ', metadata=' || v_cfg.run_metadata_rules ||
            ', lineage=' || v_cfg.run_lineage
        );

        IF v_cfg.use_parallel = 'Y' THEN
            pkg_trade_parallel.run_parallel_pipeline(
                p_parallel_level => v_cfg.parallel_level,
                p_batch_id       => v_source_batch_id,
                p_loaded_rows    => v_loaded_rows,
                p_elapsed_ms     => v_parallel_elapsed
            );

            log_metric(v_orchestration_batch_id, 'parallel_source_batch_id', v_source_batch_id);
            log_metric(v_orchestration_batch_id, 'parallel_elapsed_ms', v_parallel_elapsed);
        ELSE
            v_source_batch_id := v_orchestration_batch_id;

            UPDATE stg_trade_raw
               SET batch_id = v_source_batch_id,
                   processing_status = 'NEW',
                   error_count = 0,
                   processed_at = NULL
             WHERE processing_status IN ('NEW','REJECTED')
                OR batch_id IS NULL;

            v_attached_rows := SQL%ROWCOUNT;
            log_metric(v_orchestration_batch_id, 'attached_rows', v_attached_rows);

            pkg_trade_validate.validate_batch(v_source_batch_id);

            IF v_cfg.use_bulk = 'Y' THEN
                v_loaded_rows := pkg_trade_load_bulk.load_validated_bulk(v_source_batch_id, v_cfg.bulk_limit);
            ELSE
                pkg_trade_load.load_batch(v_source_batch_id);

                SELECT COUNT(*)
                  INTO v_loaded_rows
                  FROM stg_trade_raw
                 WHERE batch_id = v_source_batch_id
                   AND processing_status = 'PROCESSED';
            END IF;
        END IF;

        log_metric(v_orchestration_batch_id, 'source_batch_id', v_source_batch_id);
        log_metric(v_orchestration_batch_id, 'loaded_rows', v_loaded_rows);

        IF v_cfg.run_reconciliation = 'Y' THEN
            pkg_reconciliation.run_reconciliation(
                p_batch_id       => v_source_batch_id,
                p_recon_batch_id => v_recon_batch_id
            );
            log_metric(v_orchestration_batch_id, 'reconciliation_batch_id', v_recon_batch_id);
        END IF;

        IF v_cfg.run_data_quality = 'Y' THEN
            v_dq_batch_id := pkg_data_quality.run_trade_dq(v_source_batch_id);
            log_metric(v_orchestration_batch_id, 'dq_batch_id', v_dq_batch_id);
        END IF;

        IF v_cfg.run_metadata_rules = 'Y' THEN
            v_metadata_execution_id := pkg_metadata_engine.run_rule_group(v_cfg.metadata_rule_group, v_source_batch_id);
            log_metric(v_orchestration_batch_id, 'metadata_execution_id', v_metadata_execution_id);
        END IF;

        IF v_cfg.run_lineage = 'Y' THEN
            v_lineage_run_id := pkg_audit_lineage.build_lineage_for_batch(v_source_batch_id);
            log_metric(v_orchestration_batch_id, 'lineage_run_id', v_lineage_run_id);
        END IF;

        v_elapsed := (DBMS_UTILITY.GET_TIME - v_start) * 10;
        log_metric(v_orchestration_batch_id, 'pipeline_elapsed_ms', v_elapsed);

        pkg_log.info(v_orchestration_batch_id, 'PKG_PIPELINE_CONFIG',
            'Configured pipeline finished. source_batch_id=' || v_source_batch_id ||
            ', loaded_rows=' || v_loaded_rows || ', elapsed_ms=' || v_elapsed
        );

        pkg_log.end_batch(v_orchestration_batch_id, 'SUCCESS');

        UPDATE pipeline_config_run
           SET source_batch_id = v_source_batch_id,
               reconciliation_batch_id = v_recon_batch_id,
               dq_batch_id = v_dq_batch_id,
               metadata_execution_id = v_metadata_execution_id,
               lineage_run_id = v_lineage_run_id,
               status = 'SUCCESS',
               loaded_rows = v_loaded_rows,
               elapsed_ms = v_elapsed,
               ended_at = SYSTIMESTAMP
         WHERE config_run_id = v_config_run_id;

        COMMIT;
        RETURN v_config_run_id;

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RAISE_APPLICATION_ERROR(-20075, 'Pipeline config not found: ' || p_pipeline_code);
        WHEN OTHERS THEN
            v_error := SUBSTR(SQLERRM, 1, 4000);
            IF v_orchestration_batch_id IS NOT NULL THEN
                pkg_log.error(v_orchestration_batch_id, 'PKG_PIPELINE_CONFIG', v_error);
                pkg_log.end_batch(v_orchestration_batch_id, 'FAILED');
            END IF;
            IF v_config_run_id IS NOT NULL THEN
                UPDATE pipeline_config_run
                   SET status = 'FAILED',
                       error_message = v_error,
                       ended_at = SYSTIMESTAMP
                 WHERE config_run_id = v_config_run_id;
                COMMIT;
            END IF;
            RAISE;
    END run_configured_pipeline;

END pkg_pipeline_config;
/
