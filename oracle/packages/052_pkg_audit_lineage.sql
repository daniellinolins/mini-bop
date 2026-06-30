CREATE OR REPLACE PACKAGE pkg_audit_lineage AS

    FUNCTION build_lineage_for_batch(
        p_source_batch_id NUMBER
    ) RETURN NUMBER;

    FUNCTION latest_lineage_run_id RETURN NUMBER;

END pkg_audit_lineage;
/

CREATE OR REPLACE PACKAGE BODY pkg_audit_lineage AS

    FUNCTION next_run_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(lineage_run_id), 0) + 1
          INTO v_id
          FROM audit_lineage_run;
        RETURN v_id;
    END;

    FUNCTION next_lineage_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(lineage_id), 0) + 1
          INTO v_id
          FROM audit_lineage_trade;
        RETURN v_id;
    END;

    FUNCTION next_step_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT NVL(MAX(lineage_step_id), 0) + 1
          INTO v_id
          FROM audit_lineage_step;
        RETURN v_id;
    END;

    PROCEDURE add_step(
        p_lineage_id   NUMBER,
        p_step_name    VARCHAR2,
        p_step_status  VARCHAR2,
        p_message      VARCHAR2
    ) IS
        v_step_id NUMBER;
    BEGIN
        v_step_id := next_step_id;

        INSERT INTO audit_lineage_step (
            lineage_step_id,
            lineage_id,
            step_name,
            step_status,
            step_message,
            step_timestamp
        ) VALUES (
            v_step_id,
            p_lineage_id,
            UPPER(TRIM(p_step_name)),
            UPPER(TRIM(p_step_status)),
            SUBSTR(p_message, 1, 1000),
            SYSTIMESTAMP
        );
    END add_step;

    FUNCTION latest_lineage_run_id RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT MAX(lineage_run_id)
          INTO v_id
          FROM audit_lineage_run;
        RETURN v_id;
    END latest_lineage_run_id;

    FUNCTION build_lineage_for_batch(
        p_source_batch_id NUMBER
    ) RETURN NUMBER IS
        v_run_id              NUMBER;
        v_lineage_id          NUMBER;
        v_trade_id            trade.trade_id%TYPE;
        v_trade_status        trade.trade_status%TYPE;
        v_trade_created_at    trade.created_at%TYPE;
        v_event_count         NUMBER;
        v_last_event_at       TIMESTAMP;
        v_lineage_status      VARCHAR2(30);
        v_total_rows          NUMBER := 0;
        v_complete_rows       NUMBER := 0;
        v_rejected_rows       NUMBER := 0;
        v_incomplete_rows     NUMBER := 0;
    BEGIN
        v_run_id := next_run_id;

        INSERT INTO audit_lineage_run (
            lineage_run_id,
            source_batch_id,
            status,
            started_at,
            ended_at,
            total_rows,
            complete_rows,
            rejected_source_rows,
            incomplete_rows,
            created_by
        ) VALUES (
            v_run_id,
            p_source_batch_id,
            'RUNNING',
            SYSTIMESTAMP,
            NULL,
            0,
            0,
            0,
            0,
            USER
        );

        pkg_log.info(NULL, 'PKG_AUDIT_LINEAGE', 'Lineage build started for source batch_id=' || p_source_batch_id);

        DELETE FROM audit_lineage_step
         WHERE lineage_id IN (
             SELECT lineage_id
               FROM audit_lineage_trade
              WHERE source_batch_id = p_source_batch_id
         );

        DELETE FROM audit_lineage_trade
         WHERE source_batch_id = p_source_batch_id;

        FOR r IN (
            SELECT s.stg_trade_id,
                   s.external_trade_id,
                   s.source_system,
                   s.processing_status,
                   s.created_at AS raw_created_at,
                   s.processed_at
              FROM stg_trade_raw s
             WHERE s.batch_id = p_source_batch_id
             ORDER BY s.stg_trade_id
        ) LOOP
            v_total_rows := v_total_rows + 1;
            v_trade_id := NULL;
            v_trade_status := NULL;
            v_trade_created_at := NULL;
            v_event_count := 0;
            v_last_event_at := NULL;

            BEGIN
                SELECT t.trade_id,
                       t.trade_status,
                       t.created_at
                  INTO v_trade_id,
                       v_trade_status,
                       v_trade_created_at
                  FROM trade t
                 WHERE t.external_trade_id = r.external_trade_id
                   AND t.source_system = r.source_system
                 FETCH FIRST 1 ROWS ONLY;
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    v_trade_id := NULL;
                    v_trade_status := NULL;
                    v_trade_created_at := NULL;
            END;

            IF v_trade_id IS NOT NULL THEN
                SELECT COUNT(*), MAX(created_at)
                  INTO v_event_count, v_last_event_at
                  FROM trade_event
                 WHERE trade_id = v_trade_id;
            END IF;

            IF r.processing_status = 'REJECTED' THEN
                v_lineage_status := 'REJECTED_SOURCE';
                v_rejected_rows := v_rejected_rows + 1;
            ELSIF r.processing_status = 'PROCESSED'
               AND v_trade_id IS NOT NULL
               AND v_event_count > 0 THEN
                v_lineage_status := 'COMPLETE';
                v_complete_rows := v_complete_rows + 1;
            ELSE
                v_lineage_status := 'INCOMPLETE';
                v_incomplete_rows := v_incomplete_rows + 1;
            END IF;

            v_lineage_id := next_lineage_id;

            INSERT INTO audit_lineage_trade (
                lineage_id,
                lineage_run_id,
                source_batch_id,
                stg_trade_id,
                external_trade_id,
                source_system,
                staging_status,
                trade_id,
                trade_status,
                event_count,
                lineage_status,
                raw_created_at,
                processed_at,
                trade_created_at,
                last_event_at,
                created_at
            ) VALUES (
                v_lineage_id,
                v_run_id,
                p_source_batch_id,
                r.stg_trade_id,
                r.external_trade_id,
                r.source_system,
                r.processing_status,
                v_trade_id,
                v_trade_status,
                v_event_count,
                v_lineage_status,
                r.raw_created_at,
                r.processed_at,
                v_trade_created_at,
                v_last_event_at,
                SYSTIMESTAMP
            );

            add_step(v_lineage_id, 'RAW_CAPTURE', 'DONE', 'Raw staging row received. STG_TRADE_ID=' || r.stg_trade_id);

            IF r.processing_status IN ('PROCESSED', 'REJECTED') THEN
                add_step(v_lineage_id, 'VALIDATION', 'DONE', 'Validation completed with status=' || r.processing_status);
            ELSE
                add_step(v_lineage_id, 'VALIDATION', 'PENDING', 'Validation not completed. Current status=' || r.processing_status);
            END IF;

            IF v_trade_id IS NOT NULL THEN
                add_step(v_lineage_id, 'CORE_LOAD', 'DONE', 'Loaded into TRADE_ID=' || v_trade_id);
            ELSIF r.processing_status = 'REJECTED' THEN
                add_step(v_lineage_id, 'CORE_LOAD', 'NOT_REQUIRED', 'Rejected source row does not require core load');
            ELSE
                add_step(v_lineage_id, 'CORE_LOAD', 'MISSING', 'No core trade found');
            END IF;

            IF v_event_count > 0 THEN
                add_step(v_lineage_id, 'EVENT_GENERATION', 'DONE', 'Event count=' || v_event_count);
            ELSIF r.processing_status = 'REJECTED' THEN
                add_step(v_lineage_id, 'EVENT_GENERATION', 'NOT_REQUIRED', 'Rejected source row does not require events');
            ELSE
                add_step(v_lineage_id, 'EVENT_GENERATION', 'MISSING', 'No trade event found');
            END IF;
        END LOOP;

        UPDATE audit_lineage_run
           SET status = 'SUCCESS',
               ended_at = SYSTIMESTAMP,
               total_rows = v_total_rows,
               complete_rows = v_complete_rows,
               rejected_source_rows = v_rejected_rows,
               incomplete_rows = v_incomplete_rows
         WHERE lineage_run_id = v_run_id;

        pkg_log.info(NULL, 'PKG_AUDIT_LINEAGE',
            'Lineage build finished. run_id=' || v_run_id ||
            ', total=' || v_total_rows ||
            ', complete=' || v_complete_rows ||
            ', rejected_source=' || v_rejected_rows ||
            ', incomplete=' || v_incomplete_rows);

        COMMIT;
        RETURN v_run_id;

    EXCEPTION
        WHEN OTHERS THEN
            UPDATE audit_lineage_run
               SET status = 'FAILED',
                   ended_at = SYSTIMESTAMP
             WHERE lineage_run_id = v_run_id;
            pkg_log.error(NULL, 'PKG_AUDIT_LINEAGE', SQLERRM);
            COMMIT;
            RAISE;
    END build_lineage_for_batch;

END pkg_audit_lineage;
/
