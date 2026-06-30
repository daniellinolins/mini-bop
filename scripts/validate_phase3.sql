SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 3
PROMPT ===========================================

SELECT object_name, object_type, status
FROM user_objects
WHERE object_name IN ('PKG_COMMON', 'PKG_TRADE_LOOKUP')
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT LOOKUP TESTS
PROMPT ===========================================

DECLARE
    v_book_id         NUMBER;
    v_portfolio_id    NUMBER;
    v_counterparty_id NUMBER;
    v_instrument_id   NUMBER;
BEGIN
    SELECT pkg_trade_lookup.get_book_id(book_code)
      INTO v_book_id
      FROM book
     FETCH FIRST 1 ROWS ONLY;

    SELECT pkg_trade_lookup.get_portfolio_id(portfolio_code)
      INTO v_portfolio_id
      FROM portfolio
     FETCH FIRST 1 ROWS ONLY;

    SELECT pkg_trade_lookup.get_counterparty_id(counterparty_code)
      INTO v_counterparty_id
      FROM counterparty
     FETCH FIRST 1 ROWS ONLY;

    SELECT pkg_trade_lookup.get_instrument_id(instrument_code)
      INTO v_instrument_id
      FROM instrument
     FETCH FIRST 1 ROWS ONLY;

    DBMS_OUTPUT.PUT_LINE('BOOK_ID         = ' || v_book_id);
    DBMS_OUTPUT.PUT_LINE('PORTFOLIO_ID    = ' || v_portfolio_id);
    DBMS_OUTPUT.PUT_LINE('COUNTERPARTY_ID = ' || v_counterparty_id);
    DBMS_OUTPUT.PUT_LINE('INSTRUMENT_ID   = ' || v_instrument_id);

    IF pkg_trade_lookup.currency_exists('EUR') THEN
        DBMS_OUTPUT.PUT_LINE('Currency EUR exists');
    ELSE
        DBMS_OUTPUT.PUT_LINE('Currency EUR not found');
    END IF;
END;
/
