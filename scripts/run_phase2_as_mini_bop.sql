SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 2
PROMPT LOGGING AND TRADE VALIDATION
PROMPT ===========================================

PROMPT Compiling dependencies...
@oracle/packages/020_pkg_common.sql
@oracle/packages/021_pkg_log.sql
@oracle/packages/030_pkg_trade_validate.sql

PROMPT Checking compilation errors...
SHOW ERRORS PACKAGE pkg_common
SHOW ERRORS PACKAGE BODY pkg_common
SHOW ERRORS PACKAGE pkg_log
SHOW ERRORS PACKAGE BODY pkg_log
SHOW ERRORS PACKAGE pkg_trade_validate
SHOW ERRORS PACKAGE BODY pkg_trade_validate

PROMPT Phase 2 installation completed.
