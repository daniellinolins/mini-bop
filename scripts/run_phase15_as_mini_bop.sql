SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 15
PROMPT METADATA DRIVEN ENGINE
PROMPT ===========================================

PROMPT Creating metadata engine tables and rules...
@oracle/ddl/150_create_metadata_engine_tables.sql

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating metadata engine views...
@oracle/views/150_metadata_engine_views.sql

PROMPT Checking PKG_METADATA_ENGINE errors...
SHOW ERRORS PACKAGE pkg_metadata_engine
SHOW ERRORS PACKAGE BODY pkg_metadata_engine

PROMPT Phase 15 installation completed.
