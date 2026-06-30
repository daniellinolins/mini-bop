CREATE OR REPLACE PACKAGE pkg_reconciliation AS

    PROCEDURE run_reconciliation(
        p_batch_id      IN  NUMBER DEFAULT NULL,
        p_recon_batch_id OUT NUMBER
    );

    FUNCTION get_latest_batch_id RETURN NUMBER;

END pkg_reconciliation;
/

CREATE OR REPLACE PACKAGE BODY pkg_reconciliation AS

    FUNCTION get_latest_batch_id RETURN NUMBER IS
        v_batch_id etl_batch.batch_id%TYPE;
    BEGIN
        SELECT MAX(batch_id)
          INTO v_batch_id
          FROM etl_batch
         WHERE status = 'SUCCESS';

        RETURN v_batch_id;
    END get_latest_batch_id;

    FUNCTION count_staging_rows(
        p_batch_id NUMBER,
        p_status   VARCHAR2 DEFAULT NULL
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND (p_status IS NULL OR processing_status = p_status);

        RETURN v_count;
    END count_staging_rows;

    FUNCTION count_loaded_trades(
        p_batch_id NUMBER
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM trade t
         WHERE EXISTS (
                SELECT 1
                  FROM stg_trade_raw s
                 WHERE s.batch_id = p_batch_id
                   AND s.processing_status = 'PROCESSED'
                   AND s.external_trade_id = t.external_trade_id
                   AND s.source_system = t.source_system
         );

        RETURN v_count;
    END count_loaded_trades;

    FUNCTION count_trade_events(
        p_batch_id NUMBER
    ) RETURN NUMBER IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM trade_event e
         WHERE EXISTS (
                SELECT 1
                  FROM trade t
                  JOIN stg_trade_raw s
                    ON s.external_trade_id = t.external_trade_id
                   AND s.source_system = t.source_system
                 WHERE s.batch_id = p_batch_id
                   AND s.processing_status = 'PROCESSED'
                   AND e.trade_id = t.trade_id
         );

        RETURN v_count;
    END count_trade_events;

    PROCEDURE log_metric(
        p_batch_id NUMBER,
        p_name     VARCHAR2,
        p_value    NUMBER
    ) IS
    BEGIN
        pkg_log.info(
            p_batch_id    => p_batch_id,
            p_module_name => 'PKG_RECONCILIATION',
            p_message     => 'RECON_METRIC|' || p_name || '=' || TO_CHAR(p_value)
        );
    END log_metric;

    PROCEDURE run_reconciliation(
        p_batch_id       IN  NUMBER DEFAULT NULL,
        p_recon_batch_id OUT NUMBER
    ) IS
        v_source_batch_id     NUMBER;
        v_recon_batch_id      NUMBER;
        v_total_staging       NUMBER;
        v_processed_staging   NUMBER;
        v_rejected_staging    NUMBER;
        v_loaded_trades       NUMBER;
        v_trade_events        NUMBER;
        v_missing_trades      NUMBER;
        v_missing_events      NUMBER;
        v_status              VARCHAR2(20);
    BEGIN
        v_source_batch_id := NVL(p_batch_id, get_latest_batch_id);

        IF v_source_batch_id IS NULL THEN
            RAISE_APPLICATION_ERROR(-20020, 'No successful batch found for reconciliation');
        END IF;

        v_recon_batch_id := pkg_log.start_batch(
            p_batch_name    => 'RECONCILIATION_BATCH',
            p_source_system => 'MINI_BOP',
            p_file_name     => 'BATCH_ID=' || v_source_batch_id
        );

        p_recon_batch_id := v_recon_batch_id;

        pkg_log.info(
            v_recon_batch_id,
            'PKG_RECONCILIATION',
            'Reconciliation started for source batch_id=' || v_source_batch_id
        );

        v_total_staging     := count_staging_rows(v_source_batch_id);
        v_processed_staging := count_staging_rows(v_source_batch_id, 'PROCESSED');
        v_rejected_staging  := count_staging_rows(v_source_batch_id, 'REJECTED');
        v_loaded_trades     := count_loaded_trades(v_source_batch_id);
        v_trade_events      := count_trade_events(v_source_batch_id);

        v_missing_trades := GREATEST(v_processed_staging - v_loaded_trades, 0);
        v_missing_events := GREATEST(v_loaded_trades - v_trade_events, 0);

        log_metric(v_recon_batch_id, 'source_batch_id', v_source_batch_id);
        log_metric(v_recon_batch_id, 'total_staging_rows', v_total_staging);
        log_metric(v_recon_batch_id, 'processed_staging_rows', v_processed_staging);
        log_metric(v_recon_batch_id, 'rejected_staging_rows', v_rejected_staging);
        log_metric(v_recon_batch_id, 'loaded_trade_rows', v_loaded_trades);
        log_metric(v_recon_batch_id, 'trade_event_rows', v_trade_events);
        log_metric(v_recon_batch_id, 'missing_trade_rows', v_missing_trades);
        log_metric(v_recon_batch_id, 'missing_event_rows', v_missing_events);

        IF v_missing_trades = 0 AND v_missing_events = 0 THEN
            v_status := 'SUCCESS';
            pkg_log.info(v_recon_batch_id, 'PKG_RECONCILIATION', 'Reconciliation finished successfully');
        ELSE
            v_status := 'WARNING';
            pkg_log.error(
                v_recon_batch_id,
                'PKG_RECONCILIATION',
                'Reconciliation found differences. missing_trades=' || v_missing_trades ||
                ', missing_events=' || v_missing_events
            );
        END IF;

        pkg_log.end_batch(v_recon_batch_id, v_status);
        COMMIT;

    EXCEPTION
        WHEN OTHERS THEN
            IF v_recon_batch_id IS NOT NULL THEN
                pkg_log.error(v_recon_batch_id, 'PKG_RECONCILIATION', SQLERRM);
                pkg_log.end_batch(v_recon_batch_id, 'FAILED');
                COMMIT;
            END IF;
            RAISE;
    END run_reconciliation;

END pkg_reconciliation;
/
