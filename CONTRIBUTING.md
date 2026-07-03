# Contributing

Mini BOP is structured as a reference implementation of an Enterprise Data Engineering platform.

Contributions should preserve the following principles:

- Clear layer ownership.
- Explicit operational validation.
- Repeatable local execution.
- Consistent naming conventions.
- Documentation aligned with enterprise engineering terminology.
- No runtime artifacts committed to source control.

## Development Guidelines

1. Keep changes scoped to a platform layer.
2. Add or update validation scripts when introducing new behavior.
3. Update documentation when changing startup, architecture or operational flow.
4. Avoid committing generated runtime files, logs or local metadata stores.
5. Prefer explicit scripts over implicit manual steps.

## Commit Style

Recommended commit format:

```text
fase XX - concise description
```

Example:

```text
fase 27.2 - professional readme and quick start
```
