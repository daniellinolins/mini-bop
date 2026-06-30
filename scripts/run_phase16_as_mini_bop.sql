SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 16
PROMPT AUDIT & DATA LINEAGE
PROMPT ===========================================

PROMPT Creating audit lineage tables...
@oracle/ddl/160_create_audit_lineage_tables.sql

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating audit lineage views...
@oracle/views/160_audit_lineage_views.sql

PROMPT Checking PKG_AUDIT_LINEAGE errors...
SHOW ERRORS PACKAGE pkg_audit_lineage
SHOW ERRORS PACKAGE BODY pkg_audit_lineage

PROMPT Phase 16 installation completed.
