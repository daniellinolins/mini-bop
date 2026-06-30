-- ============================================================
-- Mini BOP - Fase 1
-- Script 06 - Sample Staging Trades
-- Execute conectado como MINI_BOP.
-- Inclui trades válidos e inválidos para testar validação na Fase 2.
-- ============================================================

INSERT INTO etl_batch(batch_name, source_system, file_name, status)
VALUES ('DAILY_TRADE_CAPTURE_20260630','MUREX_SIM','trades_20260630.csv','RUNNING');

INSERT INTO stg_trade_raw(
    batch_id, external_trade_id, source_system, trade_date_txt, settlement_date_txt,
    book_code, portfolio_code, counterparty_code, instrument_code,
    buy_sell, quantity_txt, trade_price_txt, trade_currency, raw_payload
)
SELECT
    MAX(batch_id), 'TRD-000001', 'MUREX_SIM', '2026-06-30', '2026-07-02',
    'BOND_EU', 'PF_BOND_CORE', 'CP_BNP', 'BOND_FR_2030',
    'B', '1000000', '98.75', 'EUR',
    '{"source":"MUREX_SIM","external_trade_id":"TRD-000001"}'
FROM etl_batch;

INSERT INTO stg_trade_raw(
    batch_id, external_trade_id, source_system, trade_date_txt, settlement_date_txt,
    book_code, portfolio_code, counterparty_code, instrument_code,
    buy_sell, quantity_txt, trade_price_txt, trade_currency, raw_payload
)
SELECT
    MAX(batch_id), 'TRD-000002', 'MUREX_SIM', '2026-06-30', '2026-07-01',
    'EQ_US', 'PF_EQ_GROWTH', 'CP_JPM', 'AAPL_US',
    'S', '2500', '215.60', 'USD',
    '{"source":"MUREX_SIM","external_trade_id":"TRD-000002"}'
FROM etl_batch;

INSERT INTO stg_trade_raw(
    batch_id, external_trade_id, source_system, trade_date_txt, settlement_date_txt,
    book_code, portfolio_code, counterparty_code, instrument_code,
    buy_sell, quantity_txt, trade_price_txt, trade_currency, raw_payload
)
SELECT
    MAX(batch_id), 'TRD-000003', 'MUREX_SIM', '2026-06-30', '2026-06-30',
    'FX_SPOT', 'PF_FX_LIQ', 'CP_BARC', 'EURUSD_SPOT',
    'B', '5000000', '1.0870', 'EUR',
    '{"source":"MUREX_SIM","external_trade_id":"TRD-000003"}'
FROM etl_batch;

-- Inválido: counterparty inexistente
INSERT INTO stg_trade_raw(
    batch_id, external_trade_id, source_system, trade_date_txt, settlement_date_txt,
    book_code, portfolio_code, counterparty_code, instrument_code,
    buy_sell, quantity_txt, trade_price_txt, trade_currency, raw_payload
)
SELECT
    MAX(batch_id), 'TRD-000004', 'MUREX_SIM', '2026-06-30', '2026-07-02',
    'BOND_EU', 'PF_BOND_CORE', 'CP_UNKNOWN', 'BOND_FR_2030',
    'B', '100000', '99.10', 'EUR',
    '{"source":"MUREX_SIM","external_trade_id":"TRD-000004"}'
FROM etl_batch;

-- Inválido: quantidade negativa
INSERT INTO stg_trade_raw(
    batch_id, external_trade_id, source_system, trade_date_txt, settlement_date_txt,
    book_code, portfolio_code, counterparty_code, instrument_code,
    buy_sell, quantity_txt, trade_price_txt, trade_currency, raw_payload
)
SELECT
    MAX(batch_id), 'TRD-000005', 'MUREX_SIM', '2026-06-30', '2026-07-02',
    'BOND_EU', 'PF_BOND_CORE', 'CP_BNP', 'BOND_FR_2030',
    'B', '-100', '98.75', 'EUR',
    '{"source":"MUREX_SIM","external_trade_id":"TRD-000005"}'
FROM etl_batch;

UPDATE etl_batch
   SET status = 'SUCCESS',
       ended_at = SYSTIMESTAMP,
       total_rows = (SELECT COUNT(*) FROM stg_trade_raw WHERE batch_id = etl_batch.batch_id)
 WHERE batch_name = 'DAILY_TRADE_CAPTURE_20260630';

COMMIT;

PROMPT Sample trades inserted successfully.
