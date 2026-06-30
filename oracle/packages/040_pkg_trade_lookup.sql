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
         WHERE book_code = pkg_common.normalize_code(p_book_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_book_id;

    FUNCTION get_portfolio_id(p_portfolio_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT portfolio_id
          INTO v_id
          FROM portfolio
         WHERE portfolio_code = pkg_common.normalize_code(p_portfolio_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_portfolio_id;

    FUNCTION get_counterparty_id(p_counterparty_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT counterparty_id
          INTO v_id
          FROM counterparty
         WHERE counterparty_code = pkg_common.normalize_code(p_counterparty_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_counterparty_id;

    FUNCTION get_instrument_id(p_instrument_code VARCHAR2) RETURN NUMBER IS
        v_id NUMBER;
    BEGIN
        SELECT instrument_id
          INTO v_id
          FROM instrument
         WHERE instrument_code = pkg_common.normalize_code(p_instrument_code);

        RETURN v_id;
    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            RETURN NULL;
    END get_instrument_id;

    FUNCTION currency_exists(p_currency_code VARCHAR2) RETURN BOOLEAN IS
        v_count NUMBER;
    BEGIN
        SELECT COUNT(*)
          INTO v_count
          FROM currency
         WHERE currency_code = pkg_common.normalize_code(p_currency_code);

        RETURN v_count > 0;
    END currency_exists;

END pkg_trade_lookup;
/
