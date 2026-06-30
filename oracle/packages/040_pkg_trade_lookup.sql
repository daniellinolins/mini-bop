CREATE OR REPLACE PACKAGE pkg_trade_lookup AS

    FUNCTION get_book_id(p_book_code VARCHAR2) RETURN NUMBER;
    FUNCTION get_portfolio_id(p_portfolio_code VARCHAR2) RETURN NUMBER;
    FUNCTION get_counterparty_id(p_counterparty_code VARCHAR2) RETURN NUMBER;
    FUNCTION get_instrument_id(p_instrument_code VARCHAR2) RETURN NUMBER;
    FUNCTION currency_exists(p_currency_code VARCHAR2) RETURN BOOLEAN;

END pkg_trade_lookup;
/

CREATE OR REPLACE PACKAGE BODY pkg_trade_lookup AS

    FUNCTION get_book_id(p_book_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT book_id
          INTO v_id
          FROM book
         WHERE book_code = TRIM(p_book_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    FUNCTION get_portfolio_id(p_portfolio_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT portfolio_id
          INTO v_id
          FROM portfolio
         WHERE portfolio_code = TRIM(p_portfolio_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    FUNCTION get_counterparty_id(p_counterparty_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT counterparty_id
          INTO v_id
          FROM counterparty
         WHERE counterparty_code = TRIM(p_counterparty_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    FUNCTION get_instrument_id(p_instrument_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT instrument_id
          INTO v_id
          FROM instrument
         WHERE instrument_code = TRIM(p_instrument_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END;

    FUNCTION currency_exists(p_currency_code VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM currency
         WHERE currency_code = TRIM(UPPER(p_currency_code));

        RETURN v_count > 0;
    END;

END pkg_trade_lookup;
/