# Mini BOP - Architecture V2

## Goal

This version consolidates the Oracle PL/SQL architecture used by the Mini BOP project.

## Current Oracle Layers

```text
STG_TRADE_RAW
      |
      v
PKG_TRADE_VALIDATE
      |
      +--> STG_TRADE_ERROR
      |
      v
PKG_TRADE_LOOKUP
      |
      v
PKG_TRADE_TRANSFORM
      |
      v
PKG_TRADE_LOAD       -- next phase
      |
      v
TRADE
      |
      v
PKG_TRADE_EVENT      -- next phase
      |
      v
TRADE_EVENT
```

## Package Naming

```text
020_pkg_common.sql
021_pkg_log.sql
030_pkg_trade_validate.sql
040_pkg_trade_lookup.sql
041_pkg_trade_transform.sql
042_pkg_trade_load.sql
043_pkg_trade_event.sql
```

## Design Decisions

- `PKG_COMMON` contains reusable normalization and safe conversion functions.
- `PKG_LOG` controls batch execution and process logs.
- `PKG_TRADE_VALIDATE` validates staging records and writes rejected records to `STG_TRADE_ERROR`.
- `PKG_TRADE_LOOKUP` resolves business codes to internal IDs.
- `PKG_TRADE_TYPES` provides shared PL/SQL record types.
- `PKG_TRADE_TRANSFORM` converts staging data into normalized domain records.

## Execution Order

```sql
@scripts/run_all_plsql_core.sql
@scripts/validate_phase2.sql
@scripts/validate_phase3.sql
@scripts/validate_phase4.sql
```
