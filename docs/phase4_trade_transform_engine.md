# Mini BOP - Phase 4

## Trade Transformation Engine

This phase introduces the transformation layer of the Mini BOP processing pipeline.

## Packages

- `PKG_TRADE_TYPES`
- `PKG_TRADE_TRANSFORM`

## Goal

Transform raw staging values into a normalized PL/SQL record ready to be inserted into the core `TRADE` table.

## Source

`STG_TRADE_RAW`

This table stores incoming trade data mostly as text fields such as:

- `TRADE_DATE_TXT`
- `SETTLEMENT_DATE_TXT`
- `QUANTITY_TXT`
- `TRADE_PRICE_TXT`
- `BUY_SELL`
- `BOOK_CODE`
- `PORTFOLIO_CODE`
- `COUNTERPARTY_CODE`
- `INSTRUMENT_CODE`

## Target Shape

The transformation returns a PL/SQL record compatible with the `TRADE` table.

## Main Responsibilities

- Convert text dates to `DATE`
- Convert text numbers to `NUMBER`
- Normalize `BUY` / `SELL` into `B` / `S`
- Resolve master data IDs using `PKG_TRADE_LOOKUP`
- Calculate notional amount
- Calculate market value
- Convert amount to EUR using `FX_RATE`

## Execution

```sql
@scripts/run_phase4_as_mini_bop.sql