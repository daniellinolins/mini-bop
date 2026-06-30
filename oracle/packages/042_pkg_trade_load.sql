CREATE OR REPLACE PACKAGE pkg_trade_load AS

    FUNCTION load_stage_trade(
        p_stg_trade_id NUMBER
    ) RETURN NUMBER;

    PROCEDURE load_batch(
        p_batch_id NUMBER
    );

END pkg_trade_load;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_load AS

    FUNCTION trade_already_exists(
        p_external_trade_id VARCHAR2,
        p_source_system     VARCHAR2
    ) RETURN NUMBER IS
        v_trade_id trade.trade_id%TYPE;
    BEGIN
        SELECT trade_id
          INTO v_trade_id
          FROM trade
         WHERE external_trade_id = p_external_trade_id
           AND source_system = p_source_system;

        RETURN v_trade_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END trade_already_exists;

    FUNCTION load_stage_trade(
        p_stg_trade_id NUMBER
    ) RETURN NUMBER IS
        v_trade        pkg_trade_types.trade_rec;
        v_trade_id     trade.trade_id%TYPE;
        v_existing_id  trade.trade_id%TYPE;
    BEGIN
        v_trade := pkg_trade_transform.transform_stage_trade(p_stg_trade_id);

        v_existing_id := trade_already_exists(
                             v_trade.external_trade_id,
                             v_trade.source_system
                         );

        IF v_existing_id IS NOT NULL THEN
            UPDATE trade
               SET trade_date      = v_trade.trade_date,
                   settlement_date = v_trade.settlement_date,
                   portfolio_id    = v_trade.portfolio_id,
                   book_id         = v_trade.book_id,
                   counterparty_id = v_trade.counterparty_id,
                   instrument_id   = v_trade.instrument_id,
                   buy_sell        = v_trade.buy_sell,
                   quantity        = v_trade.quantity,
                   trade_price     = v_trade.trade_price,
                   trade_currency  = v_trade.trade_currency,
                   notional_amount = v_trade.notional_amount,
                   market_value    = v_trade.market_value,
                   amount_eur      = v_trade.amount_eur,
                   trade_status    = 'PROCESSED',
                   updated_at      = SYSTIMESTAMP
             WHERE trade_id = v_existing_id;

            v_trade_id := v_existing_id;
        ELSE
            INSERT INTO trade (
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
            ) RETURNING trade_id INTO v_trade_id;
        END IF;

        UPDATE stg_trade_raw
           SET processing_status = 'PROCESSED',
               processed_at = SYSTIMESTAMP
         WHERE stg_trade_id = p_stg_trade_id;

        RETURN v_trade_id;
    END load_stage_trade;

    PROCEDURE load_batch(
        p_batch_id NUMBER
    ) IS
        v_trade_id trade.trade_id%TYPE;
        v_loaded_count NUMBER := 0;
    BEGIN
        pkg_log.info(p_batch_id, 'PKG_TRADE_LOAD', 'Starting trade load');

        FOR r IN (
            SELECT stg_trade_id
              FROM stg_trade_raw
             WHERE batch_id = p_batch_id
               AND processing_status = 'VALIDATED'
             ORDER BY stg_trade_id
        ) LOOP
            BEGIN
                v_trade_id := load_stage_trade(r.stg_trade_id);
                v_loaded_count := v_loaded_count + 1;

                pkg_log.info(
                    p_batch_id,
                    'PKG_TRADE_LOAD',
                    'Loaded STG_TRADE_ID=' || r.stg_trade_id || ' into TRADE_ID=' || v_trade_id
                );
            EXCEPTION
                WHEN OTHERS THEN
                    UPDATE stg_trade_raw
                       SET processing_status = 'REJECTED',
                           error_count = NVL(error_count, 0) + 1,
                           processed_at = SYSTIMESTAMP
                     WHERE stg_trade_id = r.stg_trade_id;

                    pkg_log.error(
                        p_batch_id,
                        'PKG_TRADE_LOAD',
                        'Error loading STG_TRADE_ID=' || r.stg_trade_id || ': ' || SQLERRM
                    );
            END;
        END LOOP;

        pkg_log.info(p_batch_id, 'PKG_TRADE_LOAD', 'Trade load finished. Loaded rows=' || v_loaded_count);
    END load_batch;

END pkg_trade_load;
/
