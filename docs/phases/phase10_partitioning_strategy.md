# Mini BOP - Phase 10

## Partitioning Strategy

This phase introduces Oracle partitioning strategy for the Mini BOP project.

The implementation is intentionally safe: it does **not** replace the current production-like tables (`TRADE`, `TRADE_EVENT`). Instead, it creates partitioned demo tables:

- `TRADE_PART_DEMO`
- `TRADE_EVENT_PART_DEMO`

These objects allow us to validate partitioning decisions without destroying the working pipeline created in previous phases.

## Why partitioning matters

In financial trade processing platforms, tables such as trades, events, valuations and risk results can grow very quickly. Partitioning helps with:

- query pruning;
- faster historical queries;
- partition-wise maintenance;
- easier archival;
- faster purging;
- better data lifecycle management;
- improved export strategy to Hadoop/Data Lake.

## Strategy used

### TRADE_PART_DEMO

Partitioned by:

```sql
PARTITION BY RANGE (trade_date)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
```

Reason: most trade analytics and exports are date-driven.

Examples:

- daily trade capture;
- monthly reporting;
- monthly Hadoop export;
- historical archive by trade month.

### TRADE_EVENT_PART_DEMO

Partitioned by:

```sql
PARTITION BY RANGE (created_at)
INTERVAL (NUMTOYMINTERVAL(1, 'MONTH'))
```

Reason: operational event data is normally queried by creation time.

## Indexing strategy

For `TRADE_PART_DEMO`:

- local index on `trade_date`;
- local index on `(book_id, trade_date)`;
- local index on `counterparty_id`;
- global unique index on `(external_trade_id, source_system)`.

Why global unique index?

A unique key that does not include the partition key often requires a global index in Oracle. In real systems, this is a key design decision because global indexes can increase maintenance cost during partition operations.

## Why not convert TRADE directly?

Converting a normal table into a partitioned table is a migration exercise. In real systems, this is usually done through one of these approaches:

1. Create a new partitioned table and migrate data.
2. Use `DBMS_REDEFINITION`.
3. Plan partitioning at initial design time.
4. Execute controlled downtime migration.

For this reference implementation, demo partitioned tables are used to validate the partitioning strategy safely.

## Execution

```sql
@scripts/run_phase10_as_mini_bop.sql
```

## Validation

```sql
@scripts/validate_phase10.sql
```

## Interview talking points

- Why partition trades by trade date?
- Difference between local and global indexes.
- Why unique constraints are harder on partitioned tables.
- What is partition pruning?
- What are interval partitions?
- How does partitioning help Hadoop exports?
- Why partitioning is a physical design decision, not a logical modeling requirement.
- What are the risks of global indexes during partition maintenance?

## Next phase

Phase 11 will introduce instrumentation and observability, including `DBMS_APPLICATION_INFO`, runtime metrics and improved operational monitoring.
