SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 18
PROMPT ORACLE TO HADOOP EXPORT ENGINE
PROMPT ===========================================

PROMPT Creating export engine tables...
@oracle/ddl/180_create_export_engine_tables.sql

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating export engine views...
@oracle/views/180_export_engine_views.sql

PROMPT Checking PKG_HADOOP_EXPORT errors...
SHOW ERRORS PACKAGE pkg_hadoop_export
SHOW ERRORS PACKAGE BODY pkg_hadoop_export

PROMPT Phase 18 installation completed.
