# Mini BOP - Phase 16

## Audit & Data Lineage

This phase introduces audit and lineage capabilities to the Mini BOP platform.

## Purpose

The goal is to answer operational and governance questions such as:

- Where did this trade come from?
- Which batch processed it?
- Was it validated?
- Was it loaded into the core `TRADE` table?
- Were operational events generated?
- Is the trade lineage complete or incomplete?

## Objects

### Tables

- `AUDIT_LINEAGE_RUN`
- `AUDIT_LINEAGE_TRADE`
- `AUDIT_LINEAGE_STEP`

### Package

- `PKG_AUDIT_LINEAGE`

### Views

- `VW_TRADE_LINEAGE_DETAIL`
- `VW_LINEAGE_TIMELINE`
- `VW_LATEST_LINEAGE_HEALTH`
- `VW_TRADE_FULL_JOURNEY`

## Main Flow

```text
STG_TRADE_RAW
   ↓
VALIDATION
   ↓
TRADE
   ↓
TRADE_EVENT
   ↓
AUDIT_LINEAGE_TRADE
   ↓
AUDIT_LINEAGE_STEP
```

## Lineage Status

- `COMPLETE`: the staging row was processed, loaded into `TRADE`, and has at least one event.
- `REJECTED_SOURCE`: the staging row was rejected and does not require core load.
- `INCOMPLETE`: the row is not rejected, but either the core trade or event is missing.

## Execution

```sql
@scripts/run_phase16_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase16.sql
```

## Interview Talking Points

- Why lineage matters in regulated environments.
- How to trace a trade from raw staging to core processing.
- Difference between operational logging and data lineage.
- Why rejected source records are valid lineage outcomes.
- How lineage supports reconciliation, recovery and audit reviews.
