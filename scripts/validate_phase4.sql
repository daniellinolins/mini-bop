SET SERVEROUTPUT ON
SET LINESIZE 200
SET PAGESIZE 200

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 4
PROMPT ===========================================

SELECT object_name,
       object_type,
       status
FROM user_objects
WHERE object_name IN (
    'PKG_TRADE_TYPES',
    'PKG_TRADE_TRANSFORM'
)
ORDER BY object_name, object_type;

PROMPT ===========================================
PROMPT TRANSFORMATION TEST
PROMPT ===========================================

DECLARE
    v_stg_trade_id NUMBER;
    v_trade        pkg_trade_types.trade_rec;
BEGIN
    SELECT stg_trade_id
      INTO v_stg_trade_id
      FROM stg_trade_raw
     WHERE processing_status = 'VALIDATED'
     FETCH FIRST 1 ROWS ONLY;

    v_trade := pkg_trade_transform.transform_stage_trade(v_stg_trade_id);

    DBMS_OUTPUT.PUT_LINE('STG_TRADE_ID       = ' || v_stg_trade_id);
    DBMS_OUTPUT.PUT_LINE('EXTERNAL_TRADE_ID  = ' || v_trade.external_trade_id);
    DBMS_OUTPUT.PUT_LINE('SOURCE_SYSTEM      = ' || v_trade.source_system);
    DBMS_OUTPUT.PUT_LINE('TRADE_DATE         = ' || TO_CHAR(v_trade.trade_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('SETTLEMENT_DATE    = ' || TO_CHAR(v_trade.settlement_date, 'YYYY-MM-DD'));
    DBMS_OUTPUT.PUT_LINE('BOOK_ID            = ' || v_trade.book_id);
    DBMS_OUTPUT.PUT_LINE('PORTFOLIO_ID       = ' || v_trade.portfolio_id);
    DBMS_OUTPUT.PUT_LINE('COUNTERPARTY_ID    = ' || v_trade.counterparty_id);
    DBMS_OUTPUT.PUT_LINE('INSTRUMENT_ID      = ' || v_trade.instrument_id);
    DBMS_OUTPUT.PUT_LINE('BUY_SELL           = ' || v_trade.buy_sell);
    DBMS_OUTPUT.PUT_LINE('QUANTITY           = ' || v_trade.quantity);
    DBMS_OUTPUT.PUT_LINE('TRADE_PRICE        = ' || v_trade.trade_price);
    DBMS_OUTPUT.PUT_LINE('TRADE_CURRENCY     = ' || v_trade.trade_currency);
    DBMS_OUTPUT.PUT_LINE('NOTIONAL_AMOUNT    = ' || v_trade.notional_amount);
    DBMS_OUTPUT.PUT_LINE('MARKET_VALUE       = ' || v_trade.market_value);
    DBMS_OUTPUT.PUT_LINE('AMOUNT_EUR         = ' || v_trade.amount_eur);
    DBMS_OUTPUT.PUT_LINE('TRADE_STATUS       = ' || v_trade.trade_status);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('No VALIDATED records found in STG_TRADE_RAW.');
        DBMS_OUTPUT.PUT_LINE('Run @scripts/validate_phase2.sql first.');
END;
/
