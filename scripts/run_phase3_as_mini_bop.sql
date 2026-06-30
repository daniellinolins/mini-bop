SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 3
PROMPT TRADE LOOKUP ENGINE
PROMPT ===========================================

PROMPT Compiling PKG_TRADE_LOOKUP...
@oracle/packages/040_pkg_trade_lookup.sql

PROMPT Checking compilation errors...
SHOW ERRORS PACKAGE pkg_trade_lookup
SHOW ERRORS PACKAGE BODY pkg_trade_lookup

PROMPT Phase 3 installation completed.