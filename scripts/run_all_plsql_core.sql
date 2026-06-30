SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - CORE PL/SQL V2
PROMPT ===========================================

PROMPT Compiling PKG_COMMON...
@oracle/packages/020_pkg_common.sql

PROMPT Compiling PKG_LOG...
@oracle/packages/021_pkg_log.sql

PROMPT Compiling PKG_TRADE_VALIDATE...
@oracle/packages/030_pkg_trade_validate.sql

PROMPT Compiling PKG_TRADE_LOOKUP...
@oracle/packages/040_pkg_trade_lookup.sql

PROMPT Compiling PKG_TRADE_TYPES...
@oracle/types/050_pkg_trade_types.sql

PROMPT Compiling PKG_TRADE_TRANSFORM...
@oracle/packages/041_pkg_trade_transform.sql

PROMPT Checking compilation errors...
SHOW ERRORS PACKAGE pkg_common
SHOW ERRORS PACKAGE BODY pkg_common
SHOW ERRORS PACKAGE pkg_log
SHOW ERRORS PACKAGE BODY pkg_log
SHOW ERRORS PACKAGE pkg_trade_validate
SHOW ERRORS PACKAGE BODY pkg_trade_validate
SHOW ERRORS PACKAGE pkg_trade_lookup
SHOW ERRORS PACKAGE BODY pkg_trade_lookup
SHOW ERRORS PACKAGE pkg_trade_types
SHOW ERRORS PACKAGE BODY pkg_trade_types
SHOW ERRORS PACKAGE pkg_trade_transform
SHOW ERRORS PACKAGE BODY pkg_trade_transform

PROMPT Core PL/SQL V2 installation completed.
