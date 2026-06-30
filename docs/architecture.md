# Mini BOP Architecture

Fluxo principal:

```text
Input File/API
   -> Oracle Staging
   -> PL/SQL Validation Engine
   -> PL/SQL Enrichment Engine
   -> Core Trade Tables
   -> Oracle Reporting Tables
   -> Sqoop Export
   -> HDFS
   -> Hive External Tables
   -> Spark Analytics
```

A Fase 1 cobre apenas a fundação Oracle: schema, tabelas, logs, dados mestres e massa de teste.
