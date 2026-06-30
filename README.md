# Mini BOP - Financial Trade Processing Platform

Laboratório didático inspirado em arquiteturas de bancos de investimento para processamento de operações financeiras.

## Fase 1 - Oracle Core

Esta fase cria:

- usuário/schema `MINI_BOP`
- tabelas core
- tabelas staging
- tabelas de log e erro
- dados mestres
- massa inicial de trades

## Ordem de execução

1. `oracle/ddl/01_create_user.sql` como SYS/SYSTEM
2. Conectar como `MINI_BOP`
3. `oracle/ddl/02_create_tables_core.sql`
4. `oracle/ddl/03_create_tables_staging.sql`
5. `oracle/ddl/04_create_tables_log.sql`
6. `oracle/dml/05_insert_master_data.sql`
7. `oracle/dml/06_insert_sample_trades.sql`
8. `oracle/ddl/07_create_indexes.sql`
9. `oracle/ddl/08_create_views.sql`

## Validação rápida

```sql
SELECT COUNT(*) FROM stg_trade_raw;
SELECT COUNT(*) FROM instrument;
SELECT COUNT(*) FROM counterparty;
SELECT * FROM vw_stg_trade_preview;
```
