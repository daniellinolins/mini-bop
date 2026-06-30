SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 9
PROMPT PARALLEL PROCESSING ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Checking PKG_TRADE_PARALLEL errors...
SHOW ERRORS PACKAGE pkg_trade_parallel
SHOW ERRORS PACKAGE BODY pkg_trade_parallel

PROMPT Phase 9 installation completed.
