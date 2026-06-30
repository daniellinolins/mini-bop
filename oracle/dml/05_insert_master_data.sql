-- ============================================================
-- Mini BOP - Fase 1
-- Script 05 - Master Data
-- Execute conectado como MINI_BOP.
-- ============================================================

INSERT INTO currency(currency_code, currency_name) VALUES ('EUR','Euro');
INSERT INTO currency(currency_code, currency_name) VALUES ('USD','US Dollar');
INSERT INTO currency(currency_code, currency_name) VALUES ('GBP','Pound Sterling');
INSERT INTO currency(currency_code, currency_name) VALUES ('CHF','Swiss Franc');
INSERT INTO currency(currency_code, currency_name) VALUES ('JPY','Japanese Yen');

INSERT INTO book(book_code, book_name, desk_name, region_code) VALUES ('BOND_EU','European Bond Book','Fixed Income Desk','EU');
INSERT INTO book(book_code, book_name, desk_name, region_code) VALUES ('EQ_US','US Equity Book','Equity Desk','US');
INSERT INTO book(book_code, book_name, desk_name, region_code) VALUES ('FX_SPOT','FX Spot Book','FX Desk','GLOBAL');

INSERT INTO portfolio(portfolio_code, portfolio_name, book_id)
SELECT 'PF_BOND_CORE','Core Bond Portfolio', book_id FROM book WHERE book_code = 'BOND_EU';

INSERT INTO portfolio(portfolio_code, portfolio_name, book_id)
SELECT 'PF_EQ_GROWTH','Growth Equity Portfolio', book_id FROM book WHERE book_code = 'EQ_US';

INSERT INTO portfolio(portfolio_code, portfolio_name, book_id)
SELECT 'PF_FX_LIQ','FX Liquidity Portfolio', book_id FROM book WHERE book_code = 'FX_SPOT';

INSERT INTO counterparty(counterparty_code, counterparty_name, country_code, sector, rating) VALUES ('CP_BNP','BNP Paribas','FR','BANK','A');
INSERT INTO counterparty(counterparty_code, counterparty_name, country_code, sector, rating) VALUES ('CP_JPM','JP Morgan','US','BANK','A+');
INSERT INTO counterparty(counterparty_code, counterparty_name, country_code, sector, rating) VALUES ('CP_BARC','Barclays','GB','BANK','A');
INSERT INTO counterparty(counterparty_code, counterparty_name, country_code, sector, rating) VALUES ('CP_CORP1','ACME Corporation','DE','CORPORATE','BBB');

INSERT INTO instrument(instrument_code, isin, instrument_name, asset_class, product_type, currency_code, maturity_date, issuer_name)
VALUES ('BOND_FR_2030','FR000000001','France Gov Bond 2030','FIXED_INCOME','BOND','EUR', DATE '2030-06-30','France Treasury');

INSERT INTO instrument(instrument_code, isin, instrument_name, asset_class, product_type, currency_code, maturity_date, issuer_name)
VALUES ('BOND_US_2032','US000000001','US Treasury Bond 2032','FIXED_INCOME','BOND','USD', DATE '2032-12-31','US Treasury');

INSERT INTO instrument(instrument_code, isin, instrument_name, asset_class, product_type, currency_code, maturity_date, issuer_name)
VALUES ('AAPL_US','US0378331005','Apple Inc','EQUITY','STOCK','USD', NULL,'Apple Inc');

INSERT INTO instrument(instrument_code, isin, instrument_name, asset_class, product_type, currency_code, maturity_date, issuer_name)
VALUES ('EURUSD_SPOT',NULL,'EUR/USD Spot','FX','FX_SPOT','EUR', NULL,'FX Market');

INSERT INTO fx_rate(rate_date, from_currency, to_currency, rate) VALUES (DATE '2026-06-30','EUR','EUR',1);
INSERT INTO fx_rate(rate_date, from_currency, to_currency, rate) VALUES (DATE '2026-06-30','USD','EUR',0.92);
INSERT INTO fx_rate(rate_date, from_currency, to_currency, rate) VALUES (DATE '2026-06-30','GBP','EUR',1.17);
INSERT INTO fx_rate(rate_date, from_currency, to_currency, rate) VALUES (DATE '2026-06-30','CHF','EUR',1.04);
INSERT INTO fx_rate(rate_date, from_currency, to_currency, rate) VALUES (DATE '2026-06-30','JPY','EUR',0.0061);

INSERT INTO market_price(price_date, instrument_id, price, price_currency)
SELECT DATE '2026-06-30', instrument_id, 98.75, 'EUR' FROM instrument WHERE instrument_code = 'BOND_FR_2030';

INSERT INTO market_price(price_date, instrument_id, price, price_currency)
SELECT DATE '2026-06-30', instrument_id, 101.25, 'USD' FROM instrument WHERE instrument_code = 'BOND_US_2032';

INSERT INTO market_price(price_date, instrument_id, price, price_currency)
SELECT DATE '2026-06-30', instrument_id, 215.60, 'USD' FROM instrument WHERE instrument_code = 'AAPL_US';

INSERT INTO market_price(price_date, instrument_id, price, price_currency)
SELECT DATE '2026-06-30', instrument_id, 1.0870, 'USD' FROM instrument WHERE instrument_code = 'EURUSD_SPOT';

COMMIT;

PROMPT Master data inserted successfully.
