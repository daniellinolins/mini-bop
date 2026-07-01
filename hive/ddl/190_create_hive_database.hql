-- ============================================================
-- MINI BOP - PHASE 19
-- HIVE EXTERNAL TABLE & QUERY LAYER
-- 190_create_hive_database.hql
-- ============================================================

CREATE DATABASE IF NOT EXISTS mini_bop
COMMENT 'Mini BOP analytical database for trade processing lab';

USE mini_bop;

SHOW DATABASES LIKE 'mini_bop';
