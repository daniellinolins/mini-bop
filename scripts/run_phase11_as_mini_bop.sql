SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 11
PROMPT INSTRUMENTATION AND OBSERVABILITY
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating observability views...
@oracle/views/110_observability_views.sql

PROMPT Checking PKG_OBSERVABILITY errors...
SHOW ERRORS PACKAGE pkg_observability
SHOW ERRORS PACKAGE BODY pkg_observability

PROMPT Phase 11 installation completed.
