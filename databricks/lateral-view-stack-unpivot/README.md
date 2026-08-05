# Unpivoting Named Measures with `LATERAL VIEW STACK`

A narrower, complementary pattern to
[`../blended-actuals-forecast-pipeline`](../blended-actuals-forecast-pipeline):
turning a handful of *computed/aggregated* measure columns into rows, as
opposed to unpivoting pre-existing wide columns on a source table.

## `UNPIVOT` vs. `LATERAL VIEW STACK` — when to use which

| | `UNPIVOT` | `LATERAL VIEW STACK` |
|---|---|---|
| Best for | Wide **source tables** with many similarly-shaped columns (e.g. 12 monthly columns) | A **small, fixed number** of measures, often freshly computed via `SUM(...) AS x` in the same query |
| Column count | Works well even with a large `IN (...)` list | Gets unwieldy past a handful of measures — the count must be kept in sync manually |
| Failure mode if miscounted | N/A (no count parameter) | `STACK(n, ...)` with the wrong `n` misaligns labels/values or errors |

## When to Use This

- You've already aggregated several differently-named measures into one row
  per key and need them as rows (e.g. for a long-format reporting table)
- The set of measures is small and stable (a handful, not dozens)
- You're inside a `SELECT` already and don't want to materialize an
  intermediate wide table just to `UNPIVOT` it

## Common Pitfalls

- **`STACK(n, ...)` count drift**: if a metric is added or removed, the `n`
  argument must be updated to match the number of label/value pairs, or the
  output silently misaligns. Always validate output row count as a multiple
  of the input row count (see the validation query in `pipeline.sql`).
- **Mixing types across stacked values**: all values passed to `STACK` in the
  same position need compatible types, since they land in one output column.
  Cast explicitly rather than relying on implicit coercion.
