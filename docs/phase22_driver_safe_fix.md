# Phase 22 Driver-Safe Fix

This fix replaces the previous long-lineage Spark job with a deterministic driver-safe implementation for the local WSL lab.

The phase still demonstrates the same concepts:

- incremental batches
- watermark/checkpoint
- idempotent current table
- MERGE-like upsert by business key
- SCD Type 2 history
- change log
- job history
- schema evolution column (`risk_segment`)
- Gold incremental metrics

The change is implementation-level only: it avoids Spark window operations and deep logical plans for the tiny sample dataset, preventing the job from hanging in the local lab environment.
