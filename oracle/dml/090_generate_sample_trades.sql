SET SERVEROUTPUT ON

PROMPT ===========================================
PROMPT MINI BOP - GENERATE SAMPLE TRADES
PROMPT ===========================================

DECLARE
    v_start_id NUMBER;
BEGIN
    SELECT NVL(MAX(stg_trade_id), 0) + 1
      INTO v_start_id
      FROM stg_trade_raw;

    FOR i IN 1 .. 1000 LOOP
        INSERT INTO stg_trade_raw (
            stg_trade_id,
            batch_id,
            external_trade_id,
            source_system,
            trade_date_txt,
            settlement_date_txt,
            book_code,
            portfolio_code,
            counterparty_code,
            instrument_code,
            buy_sell,
            quantity_txt,
            trade_price_txt,
            trade_currency,
            raw_payload,
            processing_status,
            error_count,
            created_at,
            processed_at
        ) VALUES (
            v_start_id + i - 1,
            NULL,
            'TRD-GEN-' || TO_CHAR(v_start_id + i - 1, 'FM000000'),
            'MUREX_SIM',
            '2026-06-30',
            '2026-07-02',
            CASE MOD(i, 3) WHEN 0 THEN 'BOND_DESK' WHEN 1 THEN 'EQUITY_DESK' ELSE 'FX_DESK' END,
            CASE MOD(i, 3) WHEN 0 THEN 'PORT_BONDS' WHEN 1 THEN 'PORT_EQUITY' ELSE 'PORT_FX' END,
            CASE MOD(i, 4) WHEN 0 THEN 'CP_BANK_A' WHEN 1 THEN 'CP_BANK_B' WHEN 2 THEN 'CP_FUND_A' ELSE 'CP_CORP_A' END,
            CASE MOD(i, 4) WHEN 0 THEN 'BOND_PT_10Y' WHEN 1 THEN 'AAPL_US_EQ' WHEN 2 THEN 'EUR_USD_SPOT' ELSE 'BOND_FR_5Y' END,
            CASE MOD(i, 2) WHEN 0 THEN 'BUY' ELSE 'SELL' END,
            TO_CHAR(1000 + i),
            TO_CHAR(95 + MOD(i, 20) / 10),
            CASE MOD(i, 3) WHEN 0 THEN 'EUR' WHEN 1 THEN 'USD' ELSE 'EUR' END,
            '{"generated":true}',
            'NEW',
            0,
            SYSTIMESTAMP,
            NULL
        );
    END LOOP;

    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Generated 1000 sample trades starting at STG_TRADE_ID=' || v_start_id);
END;
/
