# Mini BOP - Phase 3

## Trade Lookup Engine

This phase introduces the lookup layer used by the trade processing pipeline.

## Package

- `PKG_TRADE_LOOKUP`

## Responsibility

The lookup package resolves business codes from staging into internal surrogate keys.

Examples:

```text
BOOK_CODE          -> BOOK_ID
PORTFOLIO_CODE     -> PORTFOLIO_ID
COUNTERPARTY_CODE  -> COUNTERPARTY_ID
INSTRUMENT_CODE    -> INSTRUMENT_ID