SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 4
PROMPT TRADE TRANSFORMATION ENGINE
PROMPT ===========================================

PROMPT Compiling dependencies...
@oracle/packages/020_pkg_common.sql
@oracle/packages/040_pkg_trade_lookup.sql
@oracle/types/050_pkg_trade_types.sql
@oracle/packages/041_pkg_trade_transform.sql

PROMPT Checking compilation errors...
SHOW ERRORS PACKAGE pkg_common
SHOW ERRORS PACKAGE BODY pkg_common
SHOW ERRORS PACKAGE pkg_trade_lookup
SHOW ERRORS PACKAGE BODY pkg_trade_lookup
SHOW ERRORS PACKAGE pkg_trade_types
SHOW ERRORS PACKAGE BODY pkg_trade_types
SHOW ERRORS PACKAGE pkg_trade_transform
SHOW ERRORS PACKAGE BODY pkg_trade_transform

PROMPT Phase 4 installation completed.
