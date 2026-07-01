-- ============================================================
-- MINI BOP - PHASE 19
-- HIVE VALIDATION QUERIES
-- 192_validate_hive_trade_queries.hql
-- ============================================================

USE mini_bop;

SELECT 'RAW_ROW_COUNT_INCLUDING_HEADER' AS metric_name, COUNT(*) AS metric_value
FROM ext_trade_core_csv_raw;

SELECT 'CURATED_ROW_COUNT' AS metric_name, COUNT(*) AS metric_value
FROM ext_trade_core_csv;

SELECT trade_status, COUNT(*) AS trades
FROM ext_trade_core_csv
GROUP BY trade_status;

SELECT trade_currency,
       COUNT(*) AS trades,
       SUM(amount_eur) AS total_amount_eur,
       SUM(notional_amount) AS total_notional
FROM ext_trade_core_csv
GROUP BY trade_currency
ORDER BY trade_currency;

SELECT buy_sell,
       COUNT(*) AS trades,
       SUM(amount_eur) AS total_amount_eur
FROM ext_trade_core_csv
GROUP BY buy_sell
ORDER BY buy_sell;

SELECT external_trade_id,
       trade_currency,
       quantity,
       trade_price,
       amount_eur,
       trade_status
FROM ext_trade_core_csv
ORDER BY trade_id;

SELECT CASE
         WHEN (SELECT COUNT(*) FROM ext_trade_core_csv_raw) = 6
          AND (SELECT COUNT(*) FROM ext_trade_core_csv) = 5
          AND (SELECT COUNT(*) FROM ext_trade_core_csv WHERE trade_status = 'PROCESSED') = 5
         THEN 'PASSED'
         ELSE 'FAILED'
       END AS hive_phase19_status;
