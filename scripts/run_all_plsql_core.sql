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

PROMPT Compiling PKG_TRADE_EVENT...
@oracle/packages/043_pkg_trade_event.sql

PROMPT Compiling PKG_TRADE_LOAD...
@oracle/packages/042_pkg_trade_load.sql

PROMPT Compiling PKG_TRADE_LOAD_BULK...
@oracle/packages/044_pkg_trade_load_bulk.sql

PROMPT Compiling PKG_BATCH_SCHEDULER...
@oracle/packages/045_pkg_batch_scheduler.sql

PROMPT Compiling PKG_TRADE_PARALLEL...
@oracle/packages/046_pkg_trade_parallel.sql

PROMPT Compiling PKG_OBSERVABILITY...
@oracle/packages/047_pkg_observability.sql

PROMPT Compiling PKG_RECONCILIATION...
@oracle/packages/048_pkg_reconciliation.sql

PROMPT Compiling PKG_RECOVERY...
@oracle/packages/049_pkg_recovery.sql

PROMPT Compiling PKG_DATA_QUALITY...
@oracle/packages/050_pkg_data_quality.sql

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
SHOW ERRORS PACKAGE pkg_trade_transform
SHOW ERRORS PACKAGE BODY pkg_trade_transform
SHOW ERRORS PACKAGE pkg_trade_event
SHOW ERRORS PACKAGE BODY pkg_trade_event
SHOW ERRORS PACKAGE pkg_trade_load
SHOW ERRORS PACKAGE BODY pkg_trade_load
SHOW ERRORS PACKAGE pkg_trade_load_bulk
SHOW ERRORS PACKAGE BODY pkg_trade_load_bulk
SHOW ERRORS PACKAGE pkg_batch_scheduler
SHOW ERRORS PACKAGE BODY pkg_batch_scheduler
SHOW ERRORS PACKAGE pkg_trade_parallel
SHOW ERRORS PACKAGE BODY pkg_trade_parallel
SHOW ERRORS PACKAGE pkg_observability
SHOW ERRORS PACKAGE BODY pkg_observability
SHOW ERRORS PACKAGE pkg_reconciliation
SHOW ERRORS PACKAGE BODY pkg_reconciliation
SHOW ERRORS PACKAGE pkg_recovery
SHOW ERRORS PACKAGE BODY pkg_recovery
SHOW ERRORS PACKAGE pkg_data_quality
SHOW ERRORS PACKAGE BODY pkg_data_quality

PROMPT Core PL/SQL V2 installation completed.
