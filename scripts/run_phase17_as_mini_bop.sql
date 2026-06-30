SET SERVEROUTPUT ON
SET DEFINE OFF

PROMPT ===========================================
PROMPT MINI BOP - PHASE 17
PROMPT CONFIGURATION DRIVEN PIPELINE
PROMPT ===========================================

PROMPT Creating pipeline configuration tables...
@oracle/ddl/170_create_pipeline_config_tables.sql

PROMPT Compiling PL/SQL core dependencies...
@scripts/run_all_plsql_core.sql

PROMPT Creating pipeline configuration views...
@oracle/views/170_pipeline_config_views.sql

PROMPT Checking PKG_PIPELINE_CONFIG errors...
SHOW ERRORS PACKAGE pkg_pipeline_config
SHOW ERRORS PACKAGE BODY pkg_pipeline_config

PROMPT Phase 17 installation completed.
