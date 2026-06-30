# Mini BOP - Phase 17

## Configuration Driven Pipeline

This phase introduces a configuration-driven orchestration layer.

## Goal

Move operational pipeline decisions from hardcoded PL/SQL calls into database configuration.

Examples:

- use bulk load or row-by-row load
- enable or disable parallel mode
- define bulk limit
- enable reconciliation
- enable data quality
- enable metadata rules
- enable audit lineage
- configure metadata rule group

## Main Objects

- `PIPELINE_CONFIG`
- `PIPELINE_CONFIG_RUN`
- `PKG_PIPELINE_CONFIG`
- `VW_PIPELINE_CONFIG_CATALOG`
- `VW_PIPELINE_CONFIG_RUNS`
- `VW_LATEST_CONFIG_PIPELINE_HEALTH`
- `VW_CONFIG_PIPELINE_LOGS`

## Main API

```sql
BEGIN
    pkg_pipeline_config.run_configured_pipeline('DAILY_TRADE_PIPELINE');
END;
/
```

## Default Pipeline

The default configuration is:

```text
DAILY_TRADE_PIPELINE
use_bulk = Y
use_parallel = N
run_reconciliation = Y
run_data_quality = Y
run_metadata_rules = Y
run_lineage = Y
metadata_rule_group = TRADE_STAGING_DQ
```

## Execution Flow

```text
PIPELINE_CONFIG
      |
      v
PKG_PIPELINE_CONFIG
      |
      +--> validation
      +--> load / bulk / parallel
      +--> reconciliation
      +--> data quality
      +--> metadata rules
      +--> lineage
      v
PIPELINE_CONFIG_RUN
```

## Interview Talking Points

- Why move pipeline flags into metadata?
- How can this reduce deployments?
- What are the trade-offs of configuration-driven systems?
- How would you secure configuration changes?
- How would this connect to an external orchestrator such as Airflow?
