# Mini BOP - Phase 15

## Metadata Driven Engine

This phase introduces a metadata-driven rule engine for the Mini BOP platform.

Instead of hardcoding all control rules in PL/SQL packages, rules are now stored as metadata in database tables and interpreted dynamically by a generic PL/SQL engine.

## Objects

### Tables

- `MD_RULE_GROUP`
- `MD_RULE_DEFINITION`
- `MD_RULE_EXECUTION`
- `MD_RULE_EXECUTION_RESULT`

### Package

- `PKG_METADATA_ENGINE`

### Views

- `VW_MD_RULE_CATALOG`
- `VW_MD_EXECUTION_SUMMARY`
- `VW_MD_RULE_RESULTS`
- `VW_LATEST_MD_ENGINE_HEALTH`
- `VW_MD_FAILED_RULES`

## Why this matters

Financial platforms often need to add, disable or modify controls without redeploying code.

A metadata-driven engine allows operational teams to control validations and reconciliation checks using tables.

## Rule model

Each rule defines:

- rule group
- rule code
- target table
- target column
- rule type
- severity
- failure condition
- active flag
- execution order

Example:

```sql
processing_status = 'PROCESSED'
AND NOT EXISTS (
    SELECT 1
    FROM trade tr
    WHERE tr.external_trade_id = t.external_trade_id
      AND tr.source_system = t.source_system
)
```

## Execution flow

```text
Source Batch
    |
    v
PKG_METADATA_ENGINE.RUN_RULE_GROUP
    |
    v
Read active metadata rules
    |
    v
Execute dynamic rule SQL
    |
    v
Store rule results
    |
    v
Compute health status
```

## Interview talking points

- Why move rules from code to metadata?
- What are the risks of dynamic SQL?
- How do you control supported target tables?
- How do you avoid SQL injection in a metadata rule engine?
- Why use rule groups?
- How does this pattern help regulatory reporting platforms?
