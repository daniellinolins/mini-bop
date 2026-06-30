# Mini BOP - Phase 6

## Trade Event Engine

This phase introduces the event layer of the Mini BOP trade processing pipeline.

## Packages

- `PKG_TRADE_EVENT`
- Updated `PKG_TRADE_LOAD`
- Updated `PKG_LOG`

## Goal

Record operational events for trades inserted or updated by the load engine.

## Flow

```text
STG_TRADE_RAW
      |
      v
PKG_TRADE_VALIDATE
      |
      v
PKG_TRADE_LOAD
      |
      +--> TRADE
      |
      +--> PKG_TRADE_EVENT
                |
                v
           TRADE_EVENT
```

## Event Strategy

The existing `TRADE_EVENT` table restricts event types to:

- `CAPTURE`
- `VALIDATION`
- `ENRICHMENT`
- `PROCESSING`
- `EXPORT`
- `RECONCILIATION`

Therefore, semantic actions such as `TRADE_CREATED` and `TRADE_UPDATED` are stored in `EVENT_MESSAGE`, while the technical event type remains compatible with the existing check constraint.

Examples:

```text
EVENT_TYPE    = CAPTURE
EVENT_STATUS  = SUCCESS
EVENT_MESSAGE = TRADE_CREATED from STG_TRADE_ID=1
```

```text
EVENT_TYPE    = PROCESSING
EVENT_STATUS  = SUCCESS
EVENT_MESSAGE = TRADE_UPDATED from STG_TRADE_ID=1
```

## Load Integration

`PKG_TRADE_LOAD` now generates events automatically:

- Inserted trade: `CAPTURE / SUCCESS`
- Updated trade: `PROCESSING / SUCCESS`

## Batch Metrics Adjustment

`PKG_LOG.end_batch` now counts `VALIDATED` and `PROCESSED` as valid rows, because after load execution valid staging rows are moved from `VALIDATED` to `PROCESSED`.

## Execution

```sql
@scripts/run_phase6_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase6.sql
```

Expected result:

```text
3 staging rows PROCESSED
2 staging rows REJECTED
3 trades in TRADE
3 events in TRADE_EVENT
```

## Interview Talking Points

- Why maintain an event table for trade lifecycle tracking?
- Why avoid encoding highly-specific event names in constrained event types?
- Why store semantic detail in event messages?
- How does event history help production support and auditability?
- What would change if this became an event-sourced architecture?
- How could events later be exported to Hadoop or Kafka?
