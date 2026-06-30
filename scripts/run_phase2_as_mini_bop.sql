SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 2
PROMPT PL/SQL ETL FRAMEWORK
PROMPT ===========================================

PROMPT Compiling PKG_COMMON...
@../oracle/packages/020_pkg_common.sql

PROMPT Compiling PKG_ETL_LOG...
@../oracle/packages/021_pkg_etl_log.sql

PROMPT Compiling PKG_TRADE_VALIDATE...
@../oracle/packages/030_pkg_trade_validate.sql

PROMPT Checking compilation errors...
SHOW ERRORS PACKAGE pkg_common
SHOW ERRORS PACKAGE BODY pkg_common

SHOW ERRORS PACKAGE pkg_etl_log
SHOW ERRORS PACKAGE BODY pkg_etl_log

SHOW ERRORS PACKAGE pkg_trade_validate
SHOW ERRORS PACKAGE BODY pkg_trade_validate

PROMPT Phase 2 installation completed.