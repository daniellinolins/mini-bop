# Module 07 — Recovery

> Designing resilient batch pipelines capable of recovering from failures safely.

---

# Why Recovery Exists

Enterprise pipelines must assume that failures will eventually happen.

Recovery is the discipline of restarting processing without corrupting data or losing traceability.

Mini BOP models recovery as an explicit architectural capability rather than an operational workaround.

---

# Failure Scenario

```mermaid
graph LR
A[Batch Started]
--> B[Processing]
--> C[Failure]
--> D[Recovery]
--> E[Replay]
--> F[Successful Completion]
```

---

# Recovery Strategies

## Selective Recovery

Only failed or rejected records are prepared for reprocessing.

Benefits:

- reduced execution time
- minimal data movement
- lower operational risk

---

## Full Replay

The complete batch is replayed.

Useful when:

- execution integrity cannot be guaranteed;
- infrastructure failures affected the whole batch.

---

# Architectural Principles

- Never overwrite historical executions.
- Preserve auditability.
- Reuse the standard pipeline.
- Keep recovery idempotent.

---

# Relationship with Batch Processing

Recovery depends on the existence of execution metadata.

```text
Batch
    ↓
Failure
    ↓
Recovery Batch
    ↓
Normal Processing Pipeline
```

This keeps the operational history intact.

---

# Operational Benefits

Recovery enables:

- controlled retries;
- operational resilience;
- traceability;
- reproducibility;
- post-incident analysis.

---

# Looking Ahead

Modern orchestrators such as Apache Airflow provide retry policies and task recovery.

Mini BOP demonstrates the same architectural responsibility inside the Oracle layer, making it easier to understand future migrations.

---

# Engineering Notes

Recovery should never introduce a second implementation of the business rules.

Instead, it should prepare data and invoke the same validated processing pipeline.

This minimizes code duplication and reduces maintenance costs.

---

# Summary

After this module you should understand:

- Why recovery is essential.
- The difference between selective recovery and replay.
- Why idempotent processing matters.
- How Mini BOP separates operational recovery from business logic.

---

# Next Module

➡ **08_RECONCILIATION.md**
