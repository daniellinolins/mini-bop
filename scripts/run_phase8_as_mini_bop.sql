SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 8
PROMPT BATCH SCHEDULER
PROMPT ===========================================

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Checking PKG_BATCH_SCHEDULER errors...
SHOW ERRORS PACKAGE pkg_batch_scheduler
SHOW ERRORS PACKAGE BODY pkg_batch_scheduler

PROMPT Phase 8 installation completed.
