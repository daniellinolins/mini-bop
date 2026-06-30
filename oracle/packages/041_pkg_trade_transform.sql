CREATE OR REPLACE PACKAGE pkg_trade_transform AS

    FUNCTION calculate_notional(
        p_quantity NUMBER,
        p_price    NUMBER
    ) RETURN NUMBER;

    FUNCTION calculate_amount_eur(
        p_amount         NUMBER,
        p_trade_currency VARCHAR2,
        p_trade_date     DATE
    ) RETURN NUMBER;

    FUNCTION transform_stage_trade(
        p_stg_trade_id NUMBER
    ) RETURN pkg_trade_types.trade_rec;

END pkg_trade_transform;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_transform AS

    FUNCTION calculate_notional(
        p_quantity NUMBER,
        p_price    NUMBER
    ) RETURN NUMBER IS
    BEGIN
        IF p_quantity IS NULL OR p_price IS NULL THEN
            RETURN NULL;
        END IF;

        RETURN ROUND(p_quantity * p_price, 4);
    END calculate_notional;

    FUNCTION calculate_amount_eur(
        p_amount         NUMBER,
        p_trade_currency VARCHAR2,
        p_trade_date     DATE
    ) RETURN NUMBER IS
        v_rate fx_rate.rate%TYPE;
    BEGIN
        IF p_amount IS NULL THEN
            RETURN NULL;
        END IF;

        IF pkg_common.normalize_code(p_trade_currency) = 'EUR' THEN
            RETURN ROUND(p_amount, 4);
        END IF;

        SELECT rate
          INTO v_rate
          FROM fx_rate
         WHERE from_currency = pkg_common.normalize_code(p_trade_currency)
           AND to_currency = 'EUR'
           AND rate_date = (
                SELECT MAX(rate_date)
                  FROM fx_rate
                 WHERE from_currency = pkg_common.normalize_code(p_trade_currency)
                   AND to_currency = 'EUR'
                   AND rate_date <= p_trade_date
           );

        RETURN ROUND(p_amount * v_rate, 4);
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END calculate_amount_eur;

    FUNCTION transform_stage_trade(
        p_stg_trade_id NUMBER
    ) RETURN pkg_trade_types.trade_rec IS
        v_stg      stg_trade_raw%ROWTYPE;
        v_trade    pkg_trade_types.trade_rec;
        v_quantity NUMBER;
        v_price    NUMBER;
        v_notional NUMBER;
    BEGIN
        SELECT *
          INTO v_stg
          FROM stg_trade_raw
         WHERE stg_trade_id = p_stg_trade_id;

        v_quantity := pkg_common.to_number_safe(v_stg.quantity_txt);
        v_price    := pkg_common.to_number_safe(v_stg.trade_price_txt);
        v_notional := calculate_notional(v_quantity, v_price);

        v_trade.external_trade_id := TRIM(v_stg.external_trade_id);
        v_trade.source_system     := TRIM(v_stg.source_system);
        v_trade.trade_date        := pkg_common.to_date_safe(v_stg.trade_date_txt);
        v_trade.settlement_date   := pkg_common.to_date_safe(v_stg.settlement_date_txt);
        v_trade.book_id           := pkg_trade_lookup.get_book_id(v_stg.book_code);
        v_trade.portfolio_id      := pkg_trade_lookup.get_portfolio_id(v_stg.portfolio_code);
        v_trade.counterparty_id   := pkg_trade_lookup.get_counterparty_id(v_stg.counterparty_code);
        v_trade.instrument_id     := pkg_trade_lookup.get_instrument_id(v_stg.instrument_code);
        v_trade.buy_sell          := pkg_common.normalize_buy_sell(v_stg.buy_sell);
        v_trade.quantity          := v_quantity;
        v_trade.trade_price       := v_price;
        v_trade.trade_currency    := pkg_common.normalize_code(v_stg.trade_currency);
        v_trade.notional_amount   := v_notional;
        v_trade.market_value      := v_notional;
        v_trade.amount_eur        := calculate_amount_eur(v_notional, v_stg.trade_currency, v_trade.trade_date);
        v_trade.trade_status      := 'NEW';

        RETURN v_trade;
    END transform_stage_trade;

END pkg_trade_transform;
/
