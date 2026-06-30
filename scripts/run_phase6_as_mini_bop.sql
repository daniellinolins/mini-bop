SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 6
PROMPT TRADE EVENT ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Checking PKG_TRADE_EVENT errors...
SHOW ERRORS PACKAGE pkg_trade_event
SHOW ERRORS PACKAGE BODY pkg_trade_event

PROMPT Phase 6 installation completed.
