SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 5
PROMPT TRADE LOAD ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Checking PKG_TRADE_LOAD errors...
SHOW ERRORS PACKAGE pkg_trade_load
SHOW ERRORS PACKAGE BODY pkg_trade_load

PROMPT Phase 5 installation completed.
