SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 12
PROMPT RECONCILIATION ENGINE
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating reconciliation views...
@oracle/views/120_reconciliation_views.sql

PROMPT Checking PKG_RECONCILIATION errors...
SHOW ERRORS PACKAGE pkg_reconciliation
SHOW ERRORS PACKAGE BODY pkg_reconciliation

PROMPT Phase 12 installation completed.
