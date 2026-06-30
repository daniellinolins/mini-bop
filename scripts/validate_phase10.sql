SET SERVEROUTPUT ON
SET LINESIZE 220
SET PAGESIZE 200
COLUMN table_name FORMAT A30
COLUMN partition_name FORMAT A35
COLUMN high_value FORMAT A80
COLUMN index_name FORMAT A35
COLUMN locality FORMAT A10
COLUMN status FORMAT A10
COLUMN partitioning_type FORMAT A20
COLUMN interval FORMAT A30

PROMPT ===========================================
PROMPT VALIDATING MINI BOP - PHASE 10
PROMPT ===========================================

PROMPT ===========================================
PROMPT PARTITIONED TABLES
PROMPT ===========================================

SELECT table_name,
       partitioning_type,
       interval
FROM user_part_tables
WHERE table_name IN ('TRADE_PART_DEMO', 'TRADE_EVENT_PART_DEMO')
ORDER BY table_name;

PROMPT ===========================================
PROMPT TABLE PARTITIONS
PROMPT ===========================================

SELECT table_name,
       partition_name,
       partition_position,
       num_rows
FROM user_tab_partitions
WHERE table_name IN ('TRADE_PART_DEMO', 'TRADE_EVENT_PART_DEMO')
ORDER BY table_name, partition_position;

PROMPT ===========================================
PROMPT INDEX LOCALITY
PROMPT ===========================================

SELECT i.table_name,
       i.index_name,
       pi.locality,
       i.uniqueness,
       i.status
FROM user_indexes i
LEFT JOIN user_part_indexes pi
       ON pi.index_name = i.index_name
WHERE i.table_name IN ('TRADE_PART_DEMO', 'TRADE_EVENT_PART_DEMO')
ORDER BY i.table_name, i.index_name;

PROMPT ===========================================
PROMPT ROW COUNTS
PROMPT ===========================================

SELECT 'TRADE' AS table_name, COUNT(*) AS row_count FROM trade
UNION ALL
SELECT 'TRADE_PART_DEMO', COUNT(*) FROM trade_part_demo
UNION ALL
SELECT 'TRADE_EVENT', COUNT(*) FROM trade_event
UNION ALL
SELECT 'TRADE_EVENT_PART_DEMO', COUNT(*) FROM trade_event_part_demo;

PROMPT ===========================================
PROMPT PARTITION PRUNING TEST - TRADE_PART_DEMO
PROMPT ===========================================

EXPLAIN PLAN FOR
SELECT COUNT(*)
FROM trade_part_demo
WHERE trade_date >= DATE '2026-06-01'
  AND trade_date <  DATE '2026-07-01';

SELECT *
FROM TABLE(DBMS_XPLAN.DISPLAY(NULL, NULL, 'BASIC +PARTITION'));

PROMPT ===========================================
PROMPT SAMPLE QUERY
PROMPT ===========================================

SELECT trade_date,
       trade_currency,
       COUNT(*) AS trades,
       SUM(amount_eur) AS total_amount_eur
FROM trade_part_demo
GROUP BY trade_date, trade_currency
ORDER BY trade_date, trade_currency;

PROMPT Phase 10 validation completed.
