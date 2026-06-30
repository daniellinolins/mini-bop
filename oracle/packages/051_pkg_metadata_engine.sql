CREATE OR REPLACE PACKAGE pkg_metadata_engine AS

    FUNCTION run_rule_group(
        p_rule_group_code IN VARCHAR2,
        p_source_batch_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER;

    PROCEDURE run_rule_group(
        p_rule_group_code IN VARCHAR2,
        p_source_batch_id IN NUMBER DEFAULT NULL,
        p_execution_id    OUT NUMBER,
        p_batch_id        OUT NUMBER
    );

END pkg_metadata_engine;
/

CREATE OR REPLACE PACKAGE BODY pkg_metadata_engine AS

    FUNCTION next_execution_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(execution_id), 0) + 1
          INTO v_id
          FROM md_rule_execution;

        RETURN v_id;
    END next_execution_id;

    FUNCTION next_result_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(result_id), 0) + 1
          INTO v_id
          FROM md_rule_execution_result;

        RETURN v_id;
    END next_result_id;

    FUNCTION base_query(
        p_target_table    IN VARCHAR2,
        p_source_batch_id IN NUMBER
    ) RETURN VARCHAR2 IS
        v_table VARCHAR2(100) := UPPER(TRIM(p_target_table));
    BEGIN
        IF v_table = 'STG_TRADE_RAW' THEN
            IF p_source_batch_id IS NULL THEN
                RETURN ' FROM stg_trade_raw t WHERE 1=1 ';
            ELSE
                RETURN ' FROM stg_trade_raw t WHERE t.batch_id = ' || TO_CHAR(p_source_batch_id) || ' ';
            END IF;
        ELSIF v_table = 'TRADE' THEN
            IF p_source_batch_id IS NULL THEN
                RETURN ' FROM trade t WHERE 1=1 ';
            ELSE
                RETURN ' FROM trade t WHERE EXISTS (SELECT 1 FROM stg_trade_raw s WHERE s.batch_id = ' || TO_CHAR(p_source_batch_id) || ' AND s.external_trade_id = t.external_trade_id AND s.source_system = t.source_system) ';
            END IF;
        ELSE
            RAISE_APPLICATION_ERROR(-20051, 'Unsupported metadata target table: ' || p_target_table);
        END IF;
    END base_query;

    PROCEDURE execute_one_rule(
        p_execution_id    IN NUMBER,
        p_batch_id        IN NUMBER,
        p_source_batch_id IN NUMBER,
        p_rule            IN md_rule_definition%ROWTYPE
    ) IS
        v_total_rows    NUMBER := 0;
        v_failed_rows   NUMBER := 0;
        v_passed_rows   NUMBER := 0;
        v_score         NUMBER := 0;
        v_status        VARCHAR2(20);
        v_sql_total     VARCHAR2(32767);
        v_sql_failed    VARCHAR2(32767);
        v_result_id     NUMBER;

        v_rule_id       md_rule_definition.rule_id%TYPE;
        v_rule_code     md_rule_definition.rule_code%TYPE;
        v_severity      md_rule_definition.severity%TYPE;
        v_target_table  md_rule_definition.target_table%TYPE;
        v_condition     md_rule_definition.failure_condition%TYPE;
        v_error_message VARCHAR2(4000);
    BEGIN
        -- Copy record fields to scalar variables before using them in SQL DML.
        -- This avoids ORA-00984 edge cases with record-field references inside INSERT VALUES.
        v_rule_id      := p_rule.rule_id;
        v_rule_code    := p_rule.rule_code;
        v_severity     := p_rule.severity;
        v_target_table := p_rule.target_table;
        v_condition    := p_rule.failure_condition;

        v_sql_total  := 'SELECT COUNT(*) ' || base_query(v_target_table, p_source_batch_id);
        v_sql_failed := v_sql_total || ' AND (' || v_condition || ')';

        EXECUTE IMMEDIATE v_sql_total INTO v_total_rows;
        EXECUTE IMMEDIATE v_sql_failed INTO v_failed_rows;

        v_passed_rows := v_total_rows - v_failed_rows;

        IF v_total_rows = 0 THEN
            v_score := 100;
        ELSE
            v_score := ROUND((v_passed_rows / v_total_rows) * 100, 2);
        END IF;

        IF v_failed_rows = 0 THEN
            v_status := 'PASS';
        ELSIF v_severity = 'WARNING' THEN
            v_status := 'WARNING';
        ELSE
            v_status := 'FAIL';
        END IF;

        v_result_id := next_result_id;

        INSERT INTO md_rule_execution_result (
            result_id,
            execution_id,
            batch_id,
            rule_id,
            rule_code,
            severity,
            total_rows,
            failed_rows,
            passed_rows,
            quality_score,
            result_status,
            executed_sql,
            error_message,
            created_at
        ) VALUES (
            v_result_id,
            p_execution_id,
            p_batch_id,
            v_rule_id,
            v_rule_code,
            v_severity,
            v_total_rows,
            v_failed_rows,
            v_passed_rows,
            v_score,
            v_status,
            NULL,
            NULL,
            SYSTIMESTAMP
        );

        UPDATE md_rule_execution_result
           SET executed_sql = TO_CLOB(v_sql_failed)
         WHERE result_id = v_result_id;

        pkg_log.info(
            p_batch_id,
            'PKG_METADATA_ENGINE',
            'MD_RULE_RESULT|' || v_rule_code || '|status=' || v_status || '|failed=' || v_failed_rows || '|score=' || v_score
        );
    EXCEPTION
        WHEN OTHERS THEN
            v_error_message := SUBSTR(SQLERRM, 1, 4000);
            v_result_id := next_result_id;

            INSERT INTO md_rule_execution_result (
                result_id,
                execution_id,
                batch_id,
                rule_id,
                rule_code,
                severity,
                total_rows,
                failed_rows,
                passed_rows,
                quality_score,
                result_status,
                executed_sql,
                error_message,
                created_at
            ) VALUES (
                v_result_id,
                p_execution_id,
                p_batch_id,
                v_rule_id,
                v_rule_code,
                v_severity,
                0,
                0,
                0,
                0,
                'ERROR',
                NULL,
                v_error_message,
                SYSTIMESTAMP
            );

            UPDATE md_rule_execution_result
               SET executed_sql = TO_CLOB(v_sql_failed)
             WHERE result_id = v_result_id;

            pkg_log.error(
                p_batch_id,
                'PKG_METADATA_ENGINE',
                'MD_RULE_ERROR|' || NVL(v_rule_code, 'UNKNOWN_RULE') || '|' || v_error_message
            );
    END execute_one_rule;

    PROCEDURE finalize_execution(
        p_execution_id IN NUMBER,
        p_batch_id     IN NUMBER
    ) IS
        v_total_rules   NUMBER;
        v_passed_rules  NUMBER;
        v_warning_rules NUMBER;
        v_failed_rules  NUMBER;
        v_error_rules   NUMBER;
        v_avg_score     NUMBER;
        v_status        VARCHAR2(20);
    BEGIN
        SELECT COUNT(*),
               SUM(CASE WHEN result_status = 'PASS' THEN 1 ELSE 0 END),
               SUM(CASE WHEN result_status = 'WARNING' THEN 1 ELSE 0 END),
               SUM(CASE WHEN result_status = 'FAIL' THEN 1 ELSE 0 END),
               SUM(CASE WHEN result_status = 'ERROR' THEN 1 ELSE 0 END),
               ROUND(AVG(quality_score), 2)
          INTO v_total_rules,
               v_passed_rules,
               v_warning_rules,
               v_failed_rules,
               v_error_rules,
               v_avg_score
          FROM md_rule_execution_result
         WHERE execution_id = p_execution_id;

        IF NVL(v_failed_rules, 0) > 0 OR NVL(v_error_rules, 0) > 0 THEN
            v_status := 'FAILED';
        ELSE
            v_status := 'SUCCESS';
        END IF;

        UPDATE md_rule_execution
           SET ended_at = SYSTIMESTAMP,
               status = v_status,
               total_rules = NVL(v_total_rules, 0),
               passed_rules = NVL(v_passed_rules, 0),
               warning_rules = NVL(v_warning_rules, 0),
               failed_rules = NVL(v_failed_rules, 0) + NVL(v_error_rules, 0),
               avg_score = NVL(v_avg_score, 100)
         WHERE execution_id = p_execution_id;

        pkg_log.info(
            p_batch_id,
            'PKG_METADATA_ENGINE',
            'Metadata execution finished. status=' || v_status || ', total_rules=' || v_total_rules || ', avg_score=' || NVL(v_avg_score, 100)
        );

        pkg_log.end_batch(p_batch_id, v_status);
    END finalize_execution;

    PROCEDURE run_rule_group(
        p_rule_group_code IN VARCHAR2,
        p_source_batch_id IN NUMBER DEFAULT NULL,
        p_execution_id    OUT NUMBER,
        p_batch_id        OUT NUMBER
    ) IS
        v_group_code VARCHAR2(100) := UPPER(TRIM(p_rule_group_code));
        v_rule_count NUMBER;
    BEGIN
        p_batch_id := pkg_log.start_batch(
            p_batch_name    => 'METADATA_RULE_EXECUTION',
            p_source_system => 'METADATA_ENGINE',
            p_file_name     => v_group_code
        );

        p_execution_id := next_execution_id;

        SELECT COUNT(*)
          INTO v_rule_count
          FROM md_rule_definition r
          JOIN md_rule_group g ON g.rule_group_id = r.rule_group_id
         WHERE g.rule_group_code = v_group_code
           AND g.active_flag = 'Y'
           AND r.active_flag = 'Y';

        INSERT INTO md_rule_execution (
            execution_id,
            batch_id,
            source_batch_id,
            rule_group_code,
            started_at,
            ended_at,
            status,
            total_rules,
            passed_rules,
            warning_rules,
            failed_rules,
            avg_score
        ) VALUES (
            p_execution_id,
            p_batch_id,
            p_source_batch_id,
            v_group_code,
            SYSTIMESTAMP,
            NULL,
            'RUNNING',
            v_rule_count,
            0,
            0,
            0,
            NULL
        );

        pkg_log.info(
            p_batch_id,
            'PKG_METADATA_ENGINE',
            'Metadata rule group started. group=' || v_group_code || ', source_batch_id=' || NVL(TO_CHAR(p_source_batch_id), 'ALL')
        );

        FOR r IN (
            SELECT rd.*
              FROM md_rule_definition rd
              JOIN md_rule_group rg ON rg.rule_group_id = rd.rule_group_id
             WHERE rg.rule_group_code = v_group_code
               AND rg.active_flag = 'Y'
               AND rd.active_flag = 'Y'
             ORDER BY rd.execution_order, rd.rule_id
        ) LOOP
            execute_one_rule(p_execution_id, p_batch_id, p_source_batch_id, r);
        END LOOP;

        finalize_execution(p_execution_id, p_batch_id);
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            pkg_log.error(p_batch_id, 'PKG_METADATA_ENGINE', SQLERRM);

            UPDATE md_rule_execution
               SET ended_at = SYSTIMESTAMP,
                   status = 'FAILED'
             WHERE execution_id = p_execution_id;

            pkg_log.end_batch(p_batch_id, 'FAILED');
            COMMIT;
            RAISE;
    END run_rule_group;

    FUNCTION run_rule_group(
        p_rule_group_code IN VARCHAR2,
        p_source_batch_id IN NUMBER DEFAULT NULL
    ) RETURN NUMBER IS
        v_execution_id NUMBER;
        v_batch_id     NUMBER;
    BEGIN
        run_rule_group(p_rule_group_code, p_source_batch_id, v_execution_id, v_batch_id);
        RETURN v_execution_id;
    END run_rule_group;

END pkg_metadata_engine;
/
