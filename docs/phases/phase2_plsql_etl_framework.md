# Mini BOP - Phase 2

## PL/SQL ETL Framework

This phase implements the first operational PL/SQL framework for the Mini BOP project.

## Main Components

- `PKG_COMMON`
- `PKG_ETL_LOG`
- `PKG_TRADE_VALIDATE`

## Existing Tables Used

- `ETL_BATCH`
- `ETL_LOG`
- `STG_TRADE_RAW`
- `STG_TRADE_ERROR`
- `TRADE`
- `TRADE_EVENT`

## Flow

```text
STG_TRADE_RAW
      |
      v
PKG_TRADE_VALIDATE
      |
      +--> STG_TRADE_ERROR
      |
      v
STG_TRADE_RAW.PROCESSING_STATUS