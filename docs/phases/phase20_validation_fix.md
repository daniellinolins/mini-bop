# Mini BOP - Phase 20 Validation Fix

The Spark job execution was successful and generated the expected Parquet outputs.
The validation failed because the shell script invoked `python3` directly, but PySpark
is available through the Spark runtime, not necessarily installed in the system Python.

The corrected validation runs the Python validation script with `spark-submit`.
