SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 14
PROMPT DATA QUALITY FRAMEWORK
PROMPT ===========================================

PROMPT Creating Data Quality tables and rules...
@oracle/ddl/140_create_data_quality_tables.sql

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating Data Quality views...
@oracle/views/140_data_quality_views.sql

PROMPT Checking PKG_DATA_QUALITY errors...
SHOW ERRORS PACKAGE pkg_data_quality
SHOW ERRORS PACKAGE BODY pkg_data_quality

PROMPT Phase 14 installation completed.
