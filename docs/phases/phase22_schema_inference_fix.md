# Phase 22 schema inference fix

The previous driver-safe implementation failed when `spark.createDataFrame(rows)` inferred a schema from local Python dictionaries containing `None` values.

This fix defines explicit PySpark schemas for:

- incremental trade rows
- change log
- checkpoint
- job history
- metrics

This makes the local platform deterministic and avoids `[CANNOT_DETERMINE_TYPE]` errors.
