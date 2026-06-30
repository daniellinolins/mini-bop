CREATE OR REPLACE PACKAGE pkg_trade_load_bulk AS

    FUNCTION load_validated_bulk(
        p_batch_id NUMBER,
        p_limit    PLS_INTEGER DEFAULT 1000
    ) RETURN NUMBER;

END pkg_trade_load_bulk;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_load_bulk AS

    TYPE t_stg_tab IS TABLE OF stg_trade_raw%ROWTYPE INDEX BY PLS_INTEGER;

    TYPE t_num_tab IS TABLE OF NUMBER INDEX BY PLS_INTEGER;
    TYPE t_vc50_tab IS TABLE OF VARCHAR2(50) INDEX BY PLS_INTEGER;
    TYPE t_vc30_tab IS TABLE OF VARCHAR2(30) INDEX BY PLS_INTEGER;
    TYPE t_vc20_tab IS TABLE OF VARCHAR2(20) INDEX BY PLS_INTEGER;
    TYPE t_vc3_tab  IS TABLE OF VARCHAR2(3) INDEX BY PLS_INTEGER;
    TYPE t_char1_tab IS TABLE OF CHAR(1) INDEX BY PLS_INTEGER;
    TYPE t_date_tab IS TABLE OF DATE INDEX BY PLS_INTEGER;

    FUNCTION next_trade_base_id(p_count NUMBER) RETURN NUMBER IS
        v_base_id NUMBER;
    BEGIN
        SELECT NVL(MAX(trade_id), 0)
          INTO v_base_id
          FROM trade;

        RETURN v_base_id;
    END next_trade_base_id;

    FUNCTION existing_trade_id(
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
    END existing_trade_id;

    FUNCTION load_validated_bulk(
        p_batch_id NUMBER,
        p_limit    PLS_INTEGER DEFAULT 1000
    ) RETURN NUMBER IS
        CURSOR c_stg IS
            SELECT *
              FROM stg_trade_raw
             WHERE batch_id = p_batch_id
               AND processing_status = 'VALIDATED'
             ORDER BY stg_trade_id;

        v_stg_rows t_stg_tab;
        v_trade pkg_trade_types.trade_rec;

        v_next_base_id NUMBER;
        v_loaded_count NUMBER := 0;
        v_existing_trade_id NUMBER;

        v_ins_idx PLS_INTEGER := 0;
        v_upd_idx PLS_INTEGER := 0;

        v_ins_trade_id         t_num_tab;
        v_ins_external_id      t_vc50_tab;
        v_ins_source_system    t_vc30_tab;
        v_ins_trade_date       t_date_tab;
        v_ins_settlement_date  t_date_tab;
        v_ins_portfolio_id     t_num_tab;
        v_ins_book_id          t_num_tab;
        v_ins_counterparty_id  t_num_tab;
        v_ins_instrument_id    t_num_tab;
        v_ins_buy_sell         t_char1_tab;
        v_ins_quantity         t_num_tab;
        v_ins_trade_price      t_num_tab;
        v_ins_currency         t_vc3_tab;
        v_ins_notional         t_num_tab;
        v_ins_market_value     t_num_tab;
        v_ins_amount_eur       t_num_tab;
        v_ins_trade_status     t_vc20_tab;
        v_ins_stg_trade_id     t_num_tab;

        v_upd_trade_id         t_num_tab;
        v_upd_external_id      t_vc50_tab;
        v_upd_source_system    t_vc30_tab;
        v_upd_trade_date       t_date_tab;
        v_upd_settlement_date  t_date_tab;
        v_upd_portfolio_id     t_num_tab;
        v_upd_book_id          t_num_tab;
        v_upd_counterparty_id  t_num_tab;
        v_upd_instrument_id    t_num_tab;
        v_upd_buy_sell         t_char1_tab;
        v_upd_quantity         t_num_tab;
        v_upd_trade_price      t_num_tab;
        v_upd_currency         t_vc3_tab;
        v_upd_notional         t_num_tab;
        v_upd_market_value     t_num_tab;
        v_upd_amount_eur       t_num_tab;
        v_upd_trade_status     t_vc20_tab;
        v_upd_stg_trade_id     t_num_tab;

        v_processed_stg_id     t_num_tab;
        v_processed_idx        PLS_INTEGER := 0;
    BEGIN
        pkg_log.info(p_batch_id, 'PKG_TRADE_LOAD_BULK', 'Starting bulk trade load');

        v_next_base_id := next_trade_base_id(0);

        OPEN c_stg;
        LOOP
            FETCH c_stg BULK COLLECT INTO v_stg_rows LIMIT p_limit;
            EXIT WHEN v_stg_rows.COUNT = 0;

            FOR i IN 1 .. v_stg_rows.COUNT LOOP
                v_trade := pkg_trade_transform.transform_stage_trade(v_stg_rows(i).stg_trade_id);

                v_existing_trade_id := existing_trade_id(
                    v_trade.external_trade_id,
                    v_trade.source_system
                );

                IF v_existing_trade_id IS NULL THEN
                    v_ins_idx := v_ins_idx + 1;
                    v_next_base_id := v_next_base_id + 1;

                    v_ins_trade_id(v_ins_idx)        := v_next_base_id;
                    v_ins_external_id(v_ins_idx)     := v_trade.external_trade_id;
                    v_ins_source_system(v_ins_idx)   := v_trade.source_system;
                    v_ins_trade_date(v_ins_idx)      := v_trade.trade_date;
                    v_ins_settlement_date(v_ins_idx) := v_trade.settlement_date;
                    v_ins_portfolio_id(v_ins_idx)    := v_trade.portfolio_id;
                    v_ins_book_id(v_ins_idx)         := v_trade.book_id;
                    v_ins_counterparty_id(v_ins_idx) := v_trade.counterparty_id;
                    v_ins_instrument_id(v_ins_idx)   := v_trade.instrument_id;
                    v_ins_buy_sell(v_ins_idx)        := v_trade.buy_sell;
                    v_ins_quantity(v_ins_idx)        := v_trade.quantity;
                    v_ins_trade_price(v_ins_idx)     := v_trade.trade_price;
                    v_ins_currency(v_ins_idx)        := v_trade.trade_currency;
                    v_ins_notional(v_ins_idx)        := v_trade.notional_amount;
                    v_ins_market_value(v_ins_idx)    := v_trade.market_value;
                    v_ins_amount_eur(v_ins_idx)      := v_trade.amount_eur;
                    v_ins_trade_status(v_ins_idx)    := 'PROCESSED';
                    v_ins_stg_trade_id(v_ins_idx)    := v_stg_rows(i).stg_trade_id;
                ELSE
                    v_upd_idx := v_upd_idx + 1;

                    v_upd_trade_id(v_upd_idx)        := v_existing_trade_id;
                    v_upd_external_id(v_upd_idx)     := v_trade.external_trade_id;
                    v_upd_source_system(v_upd_idx)   := v_trade.source_system;
                    v_upd_trade_date(v_upd_idx)      := v_trade.trade_date;
                    v_upd_settlement_date(v_upd_idx) := v_trade.settlement_date;
                    v_upd_portfolio_id(v_upd_idx)    := v_trade.portfolio_id;
                    v_upd_book_id(v_upd_idx)         := v_trade.book_id;
                    v_upd_counterparty_id(v_upd_idx) := v_trade.counterparty_id;
                    v_upd_instrument_id(v_upd_idx)   := v_trade.instrument_id;
                    v_upd_buy_sell(v_upd_idx)        := v_trade.buy_sell;
                    v_upd_quantity(v_upd_idx)        := v_trade.quantity;
                    v_upd_trade_price(v_upd_idx)     := v_trade.trade_price;
                    v_upd_currency(v_upd_idx)        := v_trade.trade_currency;
                    v_upd_notional(v_upd_idx)        := v_trade.notional_amount;
                    v_upd_market_value(v_upd_idx)    := v_trade.market_value;
                    v_upd_amount_eur(v_upd_idx)      := v_trade.amount_eur;
                    v_upd_trade_status(v_upd_idx)    := 'PROCESSED';
                    v_upd_stg_trade_id(v_upd_idx)    := v_stg_rows(i).stg_trade_id;
                END IF;

                v_processed_idx := v_processed_idx + 1;
                v_processed_stg_id(v_processed_idx) := v_stg_rows(i).stg_trade_id;
            END LOOP;
        END LOOP;
        CLOSE c_stg;

        IF v_ins_idx > 0 THEN
            FORALL i IN 1 .. v_ins_idx
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
                    v_ins_trade_id(i),
                    v_ins_external_id(i),
                    v_ins_source_system(i),
                    v_ins_trade_date(i),
                    v_ins_settlement_date(i),
                    v_ins_portfolio_id(i),
                    v_ins_book_id(i),
                    v_ins_counterparty_id(i),
                    v_ins_instrument_id(i),
                    v_ins_buy_sell(i),
                    v_ins_quantity(i),
                    v_ins_trade_price(i),
                    v_ins_currency(i),
                    v_ins_notional(i),
                    v_ins_market_value(i),
                    v_ins_amount_eur(i),
                    v_ins_trade_status(i),
                    SYSTIMESTAMP,
                    SYSTIMESTAMP
                );

            FOR i IN 1 .. v_ins_idx LOOP
                pkg_trade_event.trade_created(
                    p_trade_id => v_ins_trade_id(i),
                    p_message  => 'TRADE_CREATED from STG_TRADE_ID=' || v_ins_stg_trade_id(i)
                );
            END LOOP;
        END IF;

        IF v_upd_idx > 0 THEN
            FORALL i IN 1 .. v_upd_idx
                UPDATE trade
                   SET trade_date        = v_upd_trade_date(i),
                       settlement_date   = v_upd_settlement_date(i),
                       portfolio_id      = v_upd_portfolio_id(i),
                       book_id           = v_upd_book_id(i),
                       counterparty_id   = v_upd_counterparty_id(i),
                       instrument_id     = v_upd_instrument_id(i),
                       buy_sell          = v_upd_buy_sell(i),
                       quantity          = v_upd_quantity(i),
                       trade_price       = v_upd_trade_price(i),
                       trade_currency    = v_upd_currency(i),
                       notional_amount   = v_upd_notional(i),
                       market_value      = v_upd_market_value(i),
                       amount_eur        = v_upd_amount_eur(i),
                       trade_status      = v_upd_trade_status(i),
                       updated_at        = SYSTIMESTAMP
                 WHERE trade_id = v_upd_trade_id(i);

            FOR i IN 1 .. v_upd_idx LOOP
                pkg_trade_event.trade_updated(
                    p_trade_id => v_upd_trade_id(i),
                    p_message  => 'TRADE_UPDATED from STG_TRADE_ID=' || v_upd_stg_trade_id(i)
                );
            END LOOP;
        END IF;

        IF v_processed_idx > 0 THEN
            FORALL i IN 1 .. v_processed_idx
                UPDATE stg_trade_raw
                   SET processing_status = 'PROCESSED',
                       processed_at = SYSTIMESTAMP
                 WHERE stg_trade_id = v_processed_stg_id(i);
        END IF;

        v_loaded_count := v_ins_idx + v_upd_idx;

        pkg_log.info(
            p_batch_id,
            'PKG_TRADE_LOAD_BULK',
            'Bulk trade load finished. Inserted=' || v_ins_idx || ', Updated=' || v_upd_idx
        );

        RETURN v_loaded_count;
    EXCEPTION
        WHEN OTHERS THEN
            IF c_stg%ISOPEN THEN
                CLOSE c_stg;
            END IF;

            pkg_log.error(
                p_batch_id,
                'PKG_TRADE_LOAD_BULK',
                SQLERRM
            );
            RAISE;
    END load_validated_bulk;

END pkg_trade_load_bulk;
/
