CREATE OR REPLACE PACKAGE pkg_hadoop_export AS

    FUNCTION export_trades_csv(
        p_source_batch_id  NUMBER DEFAULT NULL,
        p_hdfs_target_path VARCHAR2 DEFAULT '/data/mini_bop/trade'
    ) RETURN NUMBER;

    PROCEDURE validate_export(
        p_export_job_id NUMBER
    );

    FUNCTION latest_export_job_id RETURN NUMBER;

END pkg_hadoop_export;
/

CREATE OR REPLACE PACKAGE BODY pkg_hadoop_export AS

    c_module_name CONSTANT VARCHAR2(100) := 'PKG_HADOOP_EXPORT';
    c_dir_name    CONSTANT VARCHAR2(100) := 'MINI_BOP_EXPORT_DIR';

    FUNCTION next_export_job_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(export_job_id), 0) + 1
          INTO v_id
          FROM export_job;
        RETURN v_id;
    END;

    FUNCTION next_export_file_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(export_file_id), 0) + 1
          INTO v_id
          FROM export_file;
        RETURN v_id;
    END;

    FUNCTION next_manifest_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(manifest_id), 0) + 1
          INTO v_id
          FROM export_manifest;
        RETURN v_id;
    END;

    FUNCTION latest_export_job_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT MAX(export_job_id)
          INTO v_id
          FROM export_job;
        RETURN v_id;
    END;

    PROCEDURE add_manifest(
        p_export_job_id  NUMBER,
        p_key            VARCHAR2,
        p_value          VARCHAR2
    ) IS
        v_manifest_id NUMBER;
    BEGIN
        v_manifest_id := next_manifest_id;

        INSERT INTO export_manifest (
            manifest_id,
            export_job_id,
            manifest_key,
            manifest_value,
            created_at
        ) VALUES (
            v_manifest_id,
            p_export_job_id,
            p_key,
            SUBSTR(p_value, 1, 4000),
            SYSTIMESTAMP
        );
    END add_manifest;

    FUNCTION csv_escape(p_value VARCHAR2) RETURN VARCHAR2 IS
        v_value VARCHAR2(32767);
    BEGIN
        IF p_value IS NULL THEN
            RETURN '';
        END IF;

        v_value := REPLACE(p_value, '"', '""');
        RETURN '"' || v_value || '"';
    END csv_escape;

    FUNCTION export_trades_csv(
        p_source_batch_id  NUMBER DEFAULT NULL,
        p_hdfs_target_path VARCHAR2 DEFAULT '/data/mini_bop/trade'
    ) RETURN NUMBER IS
        v_export_job_id     NUMBER;
        v_data_file_id      NUMBER;
        v_manifest_file_id  NUMBER;
        v_file              UTL_FILE.FILE_TYPE;
        v_manifest_file     UTL_FILE.FILE_TYPE;
        v_file_name         VARCHAR2(255);
        v_manifest_name     VARCHAR2(255);
        v_row_count         NUMBER := 0;
        v_total_rows        NUMBER := 0;
        v_started_cs        NUMBER;
        v_elapsed_ms        NUMBER;
        v_filter_batch_id   NUMBER := p_source_batch_id;
    BEGIN
        v_started_cs := DBMS_UTILITY.GET_TIME;
        v_export_job_id := next_export_job_id;
        v_file_name := 'trade_export_' || v_export_job_id || '_' || TO_CHAR(SYSTIMESTAMP, 'YYYYMMDDHH24MISSFF3') || '.csv';
        v_manifest_name := 'trade_export_' || v_export_job_id || '_manifest.txt';

        INSERT INTO export_job (
            export_job_id,
            export_name,
            source_batch_id,
            target_system,
            export_format,
            export_status,
            output_directory,
            hdfs_target_path,
            started_at,
            ended_at,
            total_rows,
            exported_rows,
            rejected_rows,
            created_by
        ) VALUES (
            v_export_job_id,
            'TRADE_CORE_CSV_EXPORT',
            v_filter_batch_id,
            'HADOOP_HDFS',
            'CSV',
            'RUNNING',
            c_dir_name,
            p_hdfs_target_path,
            SYSTIMESTAMP,
            NULL,
            0,
            0,
            0,
            USER
        );

        pkg_log.info(NULL, c_module_name, 'Trade CSV export started. export_job_id=' || v_export_job_id || ', source_batch_id=' || NVL(TO_CHAR(v_filter_batch_id), 'ALL'));

        SELECT COUNT(*)
          INTO v_total_rows
          FROM trade t
         WHERE v_filter_batch_id IS NULL
            OR EXISTS (
                SELECT 1
                  FROM stg_trade_raw s
                 WHERE s.external_trade_id = t.external_trade_id
                   AND s.source_system = t.source_system
                   AND s.batch_id = v_filter_batch_id
                   AND s.processing_status = 'PROCESSED'
            );

        v_file := UTL_FILE.FOPEN(c_dir_name, v_file_name, 'W', 32767);
        UTL_FILE.PUT_LINE(v_file, 'trade_id,external_trade_id,source_system,trade_date,settlement_date,portfolio_id,book_id,counterparty_id,instrument_id,buy_sell,quantity,trade_price,trade_currency,notional_amount,market_value,amount_eur,trade_status,created_at,updated_at');

        FOR r IN (
            SELECT t.trade_id,
                   t.external_trade_id,
                   t.source_system,
                   t.trade_date,
                   t.settlement_date,
                   t.portfolio_id,
                   t.book_id,
                   t.counterparty_id,
                   t.instrument_id,
                   t.buy_sell,
                   t.quantity,
                   t.trade_price,
                   t.trade_currency,
                   t.notional_amount,
                   t.market_value,
                   t.amount_eur,
                   t.trade_status,
                   t.created_at,
                   t.updated_at
              FROM trade t
             WHERE v_filter_batch_id IS NULL
                OR EXISTS (
                    SELECT 1
                      FROM stg_trade_raw s
                     WHERE s.external_trade_id = t.external_trade_id
                       AND s.source_system = t.source_system
                       AND s.batch_id = v_filter_batch_id
                       AND s.processing_status = 'PROCESSED'
                )
             ORDER BY t.trade_id
        ) LOOP
            UTL_FILE.PUT_LINE(
                v_file,
                r.trade_id || ',' ||
                csv_escape(r.external_trade_id) || ',' ||
                csv_escape(r.source_system) || ',' ||
                TO_CHAR(r.trade_date, 'YYYY-MM-DD') || ',' ||
                TO_CHAR(r.settlement_date, 'YYYY-MM-DD') || ',' ||
                r.portfolio_id || ',' ||
                r.book_id || ',' ||
                r.counterparty_id || ',' ||
                r.instrument_id || ',' ||
                csv_escape(r.buy_sell) || ',' ||
                TO_CHAR(r.quantity, 'FM9999999999999990D9999', 'NLS_NUMERIC_CHARACTERS=.,') || ',' ||
                TO_CHAR(r.trade_price, 'FM9999999999999990D999999', 'NLS_NUMERIC_CHARACTERS=.,') || ',' ||
                csv_escape(r.trade_currency) || ',' ||
                TO_CHAR(r.notional_amount, 'FM9999999999999990D9999', 'NLS_NUMERIC_CHARACTERS=.,') || ',' ||
                TO_CHAR(r.market_value, 'FM9999999999999990D9999', 'NLS_NUMERIC_CHARACTERS=.,') || ',' ||
                TO_CHAR(r.amount_eur, 'FM9999999999999990D9999', 'NLS_NUMERIC_CHARACTERS=.,') || ',' ||
                csv_escape(r.trade_status) || ',' ||
                csv_escape(TO_CHAR(r.created_at, 'YYYY-MM-DD HH24:MI:SS.FF3')) || ',' ||
                csv_escape(TO_CHAR(r.updated_at, 'YYYY-MM-DD HH24:MI:SS.FF3'))
            );
            v_row_count := v_row_count + 1;
        END LOOP;

        UTL_FILE.FCLOSE(v_file);

        v_data_file_id := next_export_file_id;
        INSERT INTO export_file (
            export_file_id,
            export_job_id,
            file_role,
            file_name,
            file_path,
            hdfs_path,
            row_count,
            file_status,
            created_at
        ) VALUES (
            v_data_file_id,
            v_export_job_id,
            'DATA',
            v_file_name,
            c_dir_name || ':' || v_file_name,
            p_hdfs_target_path || '/' || v_file_name,
            v_row_count,
            'CREATED',
            SYSTIMESTAMP
        );

        add_manifest(v_export_job_id, 'export_job_id', TO_CHAR(v_export_job_id));
        add_manifest(v_export_job_id, 'export_name', 'TRADE_CORE_CSV_EXPORT');
        add_manifest(v_export_job_id, 'source_batch_id', NVL(TO_CHAR(v_filter_batch_id), 'ALL'));
        add_manifest(v_export_job_id, 'target_system', 'HADOOP_HDFS');
        add_manifest(v_export_job_id, 'format', 'CSV');
        add_manifest(v_export_job_id, 'data_file', v_file_name);
        add_manifest(v_export_job_id, 'hdfs_target_path', p_hdfs_target_path);
        add_manifest(v_export_job_id, 'row_count', TO_CHAR(v_row_count));
        add_manifest(v_export_job_id, 'exported_at', TO_CHAR(SYSTIMESTAMP, 'YYYY-MM-DD HH24:MI:SS.FF3'));

        v_manifest_file := UTL_FILE.FOPEN(c_dir_name, v_manifest_name, 'W', 32767);
        FOR m IN (
            SELECT manifest_key, manifest_value
              FROM export_manifest
             WHERE export_job_id = v_export_job_id
             ORDER BY manifest_id
        ) LOOP
            UTL_FILE.PUT_LINE(v_manifest_file, m.manifest_key || '=' || m.manifest_value);
        END LOOP;
        UTL_FILE.FCLOSE(v_manifest_file);

        v_manifest_file_id := next_export_file_id;
        INSERT INTO export_file (
            export_file_id,
            export_job_id,
            file_role,
            file_name,
            file_path,
            hdfs_path,
            row_count,
            file_status,
            created_at
        ) VALUES (
            v_manifest_file_id,
            v_export_job_id,
            'MANIFEST',
            v_manifest_name,
            c_dir_name || ':' || v_manifest_name,
            p_hdfs_target_path || '/' || v_manifest_name,
            0,
            'CREATED',
            SYSTIMESTAMP
        );

        v_elapsed_ms := (DBMS_UTILITY.GET_TIME - v_started_cs) * 10;

        UPDATE export_job
           SET export_status = 'SUCCESS',
               ended_at = SYSTIMESTAMP,
               total_rows = v_total_rows,
               exported_rows = v_row_count,
               rejected_rows = v_total_rows - v_row_count
         WHERE export_job_id = v_export_job_id;

        pkg_log.info(NULL, c_module_name, 'Trade CSV export finished. export_job_id=' || v_export_job_id || ', rows=' || v_row_count || ', elapsed_ms=' || v_elapsed_ms);

        COMMIT;
        RETURN v_export_job_id;

    EXCEPTION
        WHEN OTHERS THEN
            IF UTL_FILE.IS_OPEN(v_file) THEN
                UTL_FILE.FCLOSE(v_file);
            END IF;

            IF UTL_FILE.IS_OPEN(v_manifest_file) THEN
                UTL_FILE.FCLOSE(v_manifest_file);
            END IF;

            UPDATE export_job
               SET export_status = 'FAILED',
                   ended_at = SYSTIMESTAMP
             WHERE export_job_id = v_export_job_id;

            pkg_log.error(NULL, c_module_name, 'Trade CSV export failed. export_job_id=' || v_export_job_id || ', error=' || SQLERRM);
            COMMIT;
            RAISE;
    END export_trades_csv;

    PROCEDURE validate_export(
        p_export_job_id NUMBER
    ) IS
        v_total_rows    NUMBER;
        v_exported_rows NUMBER;
        v_file_rows     NUMBER;
    BEGIN
        SELECT total_rows, exported_rows
          INTO v_total_rows, v_exported_rows
          FROM export_job
         WHERE export_job_id = p_export_job_id;

        SELECT NVL(SUM(row_count), 0)
          INTO v_file_rows
          FROM export_file
         WHERE export_job_id = p_export_job_id
           AND file_role = 'DATA';

        IF v_total_rows != v_exported_rows OR v_exported_rows != v_file_rows THEN
            RAISE_APPLICATION_ERROR(-20080, 'Export validation failed for export_job_id=' || p_export_job_id);
        END IF;

        pkg_log.info(NULL, c_module_name, 'Export validation passed. export_job_id=' || p_export_job_id || ', rows=' || v_exported_rows);
    END validate_export;

END pkg_hadoop_export;
/
