-- Execute este script conectado como MINI_BOP.
-- Exemplo:
-- sqlplus mini_bop/mini_bop@localhost:1521/XEPDB1 @scripts/run_phase1_as_mini_bop.sql

@oracle/ddl/02_create_tables_core.sql
@oracle/ddl/03_create_tables_staging.sql
@oracle/ddl/04_create_tables_log.sql
@oracle/dml/05_insert_master_data.sql
@oracle/dml/06_insert_sample_trades.sql
@oracle/ddl/07_create_indexes.sql
@oracle/ddl/08_create_views.sql
