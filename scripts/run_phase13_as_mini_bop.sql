SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 13
PROMPT RECOVERY / RESTARTABILITY ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating recovery views...
@oracle/views/130_recovery_views.sql

PROMPT Checking PKG_RECOVERY errors...
SHOW ERRORS PACKAGE pkg_recovery
SHOW ERRORS PACKAGE BODY pkg_recovery

PROMPT Phase 13 installation completed.
