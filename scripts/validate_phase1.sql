-- Execute conectado como MINI_BOP.

SET LINESIZE 200
SET PAGESIZE 100

PROMPT === Object count ===
SELECT object_type, COUNT(*) qty
FROM user_objects
GROUP BY object_type
ORDER BY object_type;

PROMPT === Master data counts ===
SELECT 'CURRENCY' table_name, COUNT(*) qty FROM currency
UNION ALL SELECT 'BOOK', COUNT(*) FROM book
UNION ALL SELECT 'PORTFOLIO', COUNT(*) FROM portfolio
UNION ALL SELECT 'COUNTERPARTY', COUNT(*) FROM counterparty
UNION ALL SELECT 'INSTRUMENT', COUNT(*) FROM instrument
UNION ALL SELECT 'FX_RATE', COUNT(*) FROM fx_rate
UNION ALL SELECT 'MARKET_PRICE', COUNT(*) FROM market_price;

PROMPT === Staging trades ===
SELECT processing_status, COUNT(*) qty
FROM stg_trade_raw
GROUP BY processing_status;

PROMPT === Preview ===
COLUMN external_trade_id FORMAT A15
COLUMN book_code FORMAT A12
COLUMN portfolio_code FORMAT A16
COLUMN counterparty_code FORMAT A16
COLUMN instrument_code FORMAT A16
COLUMN asset_class FORMAT A15
SELECT external_trade_id, book_code, portfolio_code, counterparty_code, instrument_code, asset_class, buy_sell, quantity_txt, trade_price_txt, processing_status
FROM vw_stg_trade_preview
ORDER BY stg_trade_id;
