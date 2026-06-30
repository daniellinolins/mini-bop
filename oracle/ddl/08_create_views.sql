-- ============================================================
-- Mini BOP - Fase 1
-- Script 08 - Views
-- Execute conectado como MINI_BOP.
-- ============================================================

CREATE OR REPLACE VIEW vw_stg_trade_preview AS
SELECT
    s.stg_trade_id,
    s.batch_id,
    s.external_trade_id,
    s.source_system,
    s.trade_date_txt,
    s.book_code,
    b.book_id,
    s.portfolio_code,
    p.portfolio_id,
    s.counterparty_code,
    c.counterparty_id,
    s.instrument_code,
    i.instrument_id,
    i.asset_class,
    i.product_type,
    s.buy_sell,
    s.quantity_txt,
    s.trade_price_txt,
    s.trade_currency,
    s.processing_status
FROM stg_trade_raw s
LEFT JOIN book b ON b.book_code = s.book_code
LEFT JOIN portfolio p ON p.portfolio_code = s.portfolio_code
LEFT JOIN counterparty c ON c.counterparty_code = s.counterparty_code
LEFT JOIN instrument i ON i.instrument_code = s.instrument_code;

CREATE OR REPLACE VIEW vw_trade_exposure AS
SELECT
    t.trade_date,
    b.book_code,
    p.portfolio_code,
    c.counterparty_code,
    i.asset_class,
    i.product_type,
    t.trade_currency,
    COUNT(*) AS trade_count,
    SUM(t.notional_amount) AS total_notional,
    SUM(t.amount_eur) AS total_amount_eur
FROM trade t
JOIN book b ON b.book_id = t.book_id
JOIN portfolio p ON p.portfolio_id = t.portfolio_id
JOIN counterparty c ON c.counterparty_id = t.counterparty_id
JOIN instrument i ON i.instrument_id = t.instrument_id
GROUP BY
    t.trade_date,
    b.book_code,
    p.portfolio_code,
    c.counterparty_code,
    i.asset_class,
    i.product_type,
    t.trade_currency;

PROMPT Views created successfully.
