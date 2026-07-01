-- ============================================================
-- MINI BOP - PHASE 19
-- HIVE EXTERNAL TABLE OVER HDFS CSV EXPORT
-- 191_create_external_trade_table.hql
--
-- Design:
-- 1) ext_trade_core_csv_raw reads the CSV exactly as text fields.
-- 2) vw_trade_core_csv filters the header row and casts fields.
-- 3) ext_trade_core_csv is kept as a compatibility view name.
--
-- Important:
-- Previous phase attempts may have created ext_trade_core_csv as TABLE.
-- Hive requires DROP TABLE for tables and DROP VIEW for views, so both are used.
-- ============================================================

USE mini_bop;

DROP VIEW IF EXISTS ext_trade_core_csv;
DROP TABLE IF EXISTS ext_trade_core_csv;
DROP VIEW IF EXISTS vw_trade_core_csv;
DROP TABLE IF EXISTS ext_trade_core_csv_raw;

CREATE EXTERNAL TABLE ext_trade_core_csv_raw (
    trade_id_txt             STRING,
    external_trade_id        STRING,
    source_system            STRING,
    trade_date_txt           STRING,
    settlement_date_txt      STRING,
    portfolio_id_txt         STRING,
    book_id_txt              STRING,
    counterparty_id_txt      STRING,
    instrument_id_txt        STRING,
    buy_sell                 STRING,
    quantity_txt             STRING,
    trade_price_txt          STRING,
    trade_currency           STRING,
    notional_amount_txt      STRING,
    market_value_txt         STRING,
    amount_eur_txt           STRING,
    trade_status             STRING,
    created_at_txt           STRING,
    updated_at_txt           STRING
)
ROW FORMAT SERDE 'org.apache.hadoop.hive.serde2.OpenCSVSerde'
WITH SERDEPROPERTIES (
    'separatorChar' = ',',
    'quoteChar'     = '"',
    'escapeChar'    = '\\'
)
STORED AS TEXTFILE
LOCATION '/data/mini_bop/hive/trade_core_csv'
TBLPROPERTIES (
    'external.table.purge'='false',
    'mini_bop.phase'='19',
    'mini_bop.source'='oracle_export_csv',
    'mini_bop.layer'='raw',
    'mini_bop.note'='Raw CSV reader. Header is filtered in vw_trade_core_csv.'
);

CREATE VIEW vw_trade_core_csv AS
SELECT
    CAST(TRIM(trade_id_txt) AS BIGINT)                AS trade_id,
    external_trade_id                                 AS external_trade_id,
    source_system                                     AS source_system,
    CAST(trade_date_txt AS DATE)                      AS trade_date,
    CAST(settlement_date_txt AS DATE)                 AS settlement_date,
    CAST(TRIM(portfolio_id_txt) AS BIGINT)            AS portfolio_id,
    CAST(TRIM(book_id_txt) AS BIGINT)                 AS book_id,
    CAST(TRIM(counterparty_id_txt) AS BIGINT)         AS counterparty_id,
    CAST(TRIM(instrument_id_txt) AS BIGINT)           AS instrument_id,
    buy_sell                                          AS buy_sell,
    CAST(TRIM(quantity_txt) AS DECIMAL(20,4))         AS quantity,
    CAST(TRIM(trade_price_txt) AS DECIMAL(20,8))      AS trade_price,
    trade_currency                                    AS trade_currency,
    CAST(TRIM(notional_amount_txt) AS DECIMAL(20,4))  AS notional_amount,
    CAST(TRIM(market_value_txt) AS DECIMAL(20,4))     AS market_value,
    CAST(TRIM(amount_eur_txt) AS DECIMAL(20,4))       AS amount_eur,
    trade_status                                      AS trade_status,
    CAST(created_at_txt AS TIMESTAMP)                 AS created_at,
    CAST(updated_at_txt AS TIMESTAMP)                 AS updated_at
FROM ext_trade_core_csv_raw
WHERE trade_id_txt IS NOT NULL
  AND TRIM(trade_id_txt) RLIKE '^[0-9]+$';

-- Compatibility name used by validation scripts.
CREATE VIEW ext_trade_core_csv AS
SELECT * FROM vw_trade_core_csv;

SHOW TABLES LIKE '*trade_core_csv*';
