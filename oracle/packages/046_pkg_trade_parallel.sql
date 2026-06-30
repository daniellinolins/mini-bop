CREATE OR REPLACE PACKAGE pkg_trade_parallel AS

    PROCEDURE load_chunk(
        p_batch_id     NUMBER,
        p_start_id     NUMBER,
        p_end_id       NUMBER,
        p_loaded_rows  OUT NUMBER
    );

    PROCEDURE run_parallel_pipeline(
        p_parallel_level IN NUMBER DEFAULT 4,
        p_batch_id       OUT NUMBER,
        p_loaded_rows    OUT NUMBER,
        p_elapsed_ms     OUT NUMBER
    );

END pkg_trade_parallel;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_parallel AS

    c_module CONSTANT VARCHAR2(100) := 'PKG_TRADE_PARALLEL';

    FUNCTION next_trade_id RETURN NUMBER IS
        v_trade_id NUMBER;
    BEGIN
        SELECT NVL(MAX(trade_id), 0) + 1
          INTO v_trade_id
          FROM trade;

        RETURN v_trade_id;
    END next_trade_id;

    PROCEDURE upsert_trade(
        p_stg_trade_id IN NUMBER,
        p_batch_id     IN NUMBER,
        p_trade_id     OUT NUMBER
    ) IS
        v_trade        pkg_trade_types.trade_rec;
        v_existing_id  trade.trade_id%TYPE;
    BEGIN
        v_trade := pkg_trade_transform.transform_stage_trade(p_stg_trade_id);

        BEGIN
            SELECT trade_id
              INTO v_existing_id
              FROM trade
             WHERE external_trade_id = v_trade.external_trade_id
               AND source_system = v_trade.source_system;
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                v_existing_id := NULL;
        END;

        IF v_existing_id IS NULL THEN
            p_trade_id := next_trade_id;

            INSERT INTO trade (
                trade_id,
                external_trade_id,
                source_system,
                trade_date,
                settlement_date,
                portfolio_id,
                book_id,
                counterparty_id,
                instrument_id,
                buy_sell,
                quantity,
                trade_price,
                trade_currency,
                notional_amount,
                market_value,
                amount_eur,
                trade_status,
                created_at,
                updated_at
            ) VALUES (
                p_trade_id,
                v_trade.external_trade_id,
                v_trade.source_system,
                v_trade.trade_date,
                v_trade.settlement_date,
                v_trade.portfolio_id,
                v_trade.book_id,
                v_trade.counterparty_id,
                v_trade.instrument_id,
                v_trade.buy_sell,
                v_trade.quantity,
                v_trade.trade_price,
                v_trade.trade_currency,
                v_trade.notional_amount,
                v_trade.market_value,
                v_trade.amount_eur,
                'PROCESSED',
                SYSTIMESTAMP,
                SYSTIMESTAMP
            );

            pkg_trade_event.trade_created(
                p_trade_id => p_trade_id,
                p_message  => 'TRADE_CREATED from STG_TRADE_ID=' || p_stg_trade_id
            );
        ELSE
            p_trade_id := v_existing_id;

            UPDATE trade
               SET trade_date       = v_trade.trade_date,
                   settlement_date  = v_trade.settlement_date,
                   portfolio_id     = v_trade.portfolio_id,
                   book_id          = v_trade.book_id,
                   counterparty_id  = v_trade.counterparty_id,
                   instrument_id    = v_trade.instrument_id,
                   buy_sell         = v_trade.buy_sell,
                   quantity         = v_trade.quantity,
                   trade_price      = v_trade.trade_price,
                   trade_currency   = v_trade.trade_currency,
                   notional_amount  = v_trade.notional_amount,
                   market_value     = v_trade.market_value,
                   amount_eur       = v_trade.amount_eur,
                   trade_status     = 'PROCESSED',
                   updated_at       = SYSTIMESTAMP
             WHERE trade_id = p_trade_id;

            pkg_trade_event.trade_updated(
                p_trade_id => p_trade_id,
                p_message  => 'TRADE_UPDATED from STG_TRADE_ID=' || p_stg_trade_id
            );
        END IF;

        UPDATE stg_trade_raw
           SET processing_status = 'PROCESSED',
               processed_at = SYSTIMESTAMP
         WHERE stg_trade_id = p_stg_trade_id;
    END upsert_trade;

    PROCEDURE load_chunk(
        p_batch_id     NUMBER,
        p_start_id     NUMBER,
        p_end_id       NUMBER,
        p_loaded_rows  OUT NUMBER
    ) IS
        TYPE t_stg_id_tab IS TABLE OF stg_trade_raw.stg_trade_id%TYPE;
        v_ids         t_stg_id_tab;
        v_trade_id    trade.trade_id%TYPE;
        v_loaded_rows NUMBER := 0;
    BEGIN
        pkg_log.info(
            p_batch_id,
            c_module,
            'Chunk started. start_id=' || p_start_id || ', end_id=' || p_end_id
        );

        SELECT stg_trade_id
          BULK COLLECT INTO v_ids
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND processing_status = 'VALIDATED'
           AND stg_trade_id BETWEEN p_start_id AND p_end_id
         ORDER BY stg_trade_id;

        IF v_ids.COUNT > 0 THEN
            FOR i IN 1 .. v_ids.COUNT LOOP
                upsert_trade(
                    p_stg_trade_id => v_ids(i),
                    p_batch_id     => p_batch_id,
                    p_trade_id     => v_trade_id
                );

                v_loaded_rows := v_loaded_rows + 1;
            END LOOP;
        END IF;

        p_loaded_rows := v_loaded_rows;

        pkg_log.info(
            p_batch_id,
            c_module,
            'Chunk finished. start_id=' || p_start_id || ', end_id=' || p_end_id || ', loaded_rows=' || v_loaded_rows
        );
    EXCEPTION
        WHEN OTHERS THEN
            pkg_log.error(
                p_batch_id,
                c_module,
                'Chunk failed. start_id=' || p_start_id || ', end_id=' || p_end_id || ', error=' || SQLERRM
            );
            RAISE;
    END load_chunk;

    PROCEDURE run_parallel_pipeline(
        p_parallel_level IN NUMBER DEFAULT 4,
        p_batch_id       OUT NUMBER,
        p_loaded_rows    OUT NUMBER,
        p_elapsed_ms     OUT NUMBER
    ) IS
        v_start_time      NUMBER;
        v_end_time        NUMBER;
        v_min_id          NUMBER;
        v_max_id          NUMBER;
        v_total_validated NUMBER;
        v_parallel_level  NUMBER := GREATEST(NVL(p_parallel_level, 1), 1);
        v_chunk_size      NUMBER;
        v_start_id        NUMBER;
        v_end_id          NUMBER;
        v_chunk_rows      NUMBER;
        v_total_loaded    NUMBER := 0;
    BEGIN
        v_start_time := DBMS_UTILITY.GET_TIME;

        p_batch_id := pkg_log.start_batch(
            p_batch_name    => 'PARALLEL_TRADE_PIPELINE',
            p_source_system => 'MUREX_SIM',
            p_file_name     => 'scheduled_parallel_pipeline'
        );

        pkg_log.info(
            p_batch_id,
            c_module,
            'Parallel pipeline started. requested_parallel_level=' || v_parallel_level
        );

        /*
           Attach pending staging rows to this batch before validation.
           Previous phases did this in validation scripts, but the parallel
           pipeline must be self-contained so it can be executed by Scheduler
           or manually without external pre-processing.
        */
        UPDATE stg_trade_raw
           SET batch_id = p_batch_id,
               error_count = 0,
               processed_at = NULL
         WHERE processing_status = 'NEW'
           AND batch_id IS NULL;

        pkg_log.info(
            p_batch_id,
            c_module,
            'Attached pending staging rows to batch. rows=' || SQL%ROWCOUNT
        );

        pkg_trade_validate.validate_batch(p_batch_id);

        SELECT COUNT(*), MIN(stg_trade_id), MAX(stg_trade_id)
          INTO v_total_validated, v_min_id, v_max_id
          FROM stg_trade_raw
         WHERE batch_id = p_batch_id
           AND processing_status = 'VALIDATED';

        IF v_total_validated = 0 THEN
            p_loaded_rows := 0;
            p_elapsed_ms := ROUND((DBMS_UTILITY.GET_TIME - v_start_time) * 10);
            pkg_log.info(p_batch_id, c_module, 'No validated rows found for parallel load');
            pkg_log.end_batch(p_batch_id, 'SUCCESS');
            RETURN;
        END IF;

        v_chunk_size := CEIL((v_max_id - v_min_id + 1) / v_parallel_level);
        v_start_id := v_min_id;

        WHILE v_start_id <= v_max_id LOOP
            v_end_id := LEAST(v_start_id + v_chunk_size - 1, v_max_id);

            load_chunk(
                p_batch_id     => p_batch_id,
                p_start_id     => v_start_id,
                p_end_id       => v_end_id,
                p_loaded_rows  => v_chunk_rows
            );

            v_total_loaded := v_total_loaded + v_chunk_rows;
            v_start_id := v_end_id + 1;
        END LOOP;

        v_end_time := DBMS_UTILITY.GET_TIME;
        p_loaded_rows := v_total_loaded;
        p_elapsed_ms := ROUND((v_end_time - v_start_time) * 10);

        pkg_log.info(
            p_batch_id,
            c_module,
            'Parallel pipeline finished. loaded_rows=' || p_loaded_rows || ', elapsed_ms=' || p_elapsed_ms
        );

        pkg_log.end_batch(p_batch_id, 'SUCCESS');
    EXCEPTION
        WHEN OTHERS THEN
            IF p_batch_id IS NOT NULL THEN
                pkg_log.error(p_batch_id, c_module, SQLERRM);
                pkg_log.end_batch(p_batch_id, 'FAILED');
            END IF;
            RAISE;
    END run_parallel_pipeline;

END pkg_trade_parallel;
/
