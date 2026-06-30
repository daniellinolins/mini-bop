SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 7
PROMPT PERFORMANCE ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Compiling PKG_TRADE_LOAD_BULK...
@oracle/packages/044_pkg_trade_load_bulk.sql

PROMPT Checking PKG_TRADE_LOAD_BULK errors...
SHOW ERRORS PACKAGE pkg_trade_load_bulk
SHOW ERRORS PACKAGE BODY pkg_trade_load_bulk

PROMPT Phase 7 installation completed.
