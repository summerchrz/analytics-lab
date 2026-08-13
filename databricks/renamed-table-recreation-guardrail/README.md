# Pattern: Guardrail Against `CREATE TABLE IF NOT EXISTS` Silently Recreating a Renamed Table

## The Problem

`CREATE TABLE IF NOT EXISTS` is usually reached for as a convenience: "set
this up if it's the first run, otherwise do nothing." That's true the first
time a pipeline runs. It stops being true the moment the target table is
ever **renamed or migrated away** — because the clause doesn't error when
the table it names is missing. It just silently creates a brand-new, empty
table under that (now-stale) name, and every subsequent write lands in that
disconnected table instead.

This is a genuinely dangerous failure mode, not a theoretical one, because
of how it presents:

- The job still reports **SUCCESS** on every run — nothing failed.
- The *real* table (the one actually renamed to its new name) simply stops
  receiving new data, frozen at whatever it held at the moment of the
  rename.
- There's no error, no warning, no obviously broken dashboard — just
  quietly stale data, potentially for as long as it takes someone to
  notice a number looks off and trace it all the way back.
- It's easy to introduce during an otherwise-successful cutover: rename a
  table, update most references, and simply forget one `CREATE TABLE IF
  NOT EXISTS` cell buried in an ingestion notebook that predates the
  rename.

## The Pattern

Before any write, explicitly check that the real target table(s) already
exist — and fail loudly, not silently, if they don't:

```sql
SELECT
    CASE
        WHEN COUNT(*) = 1 THEN 'OK: table exists, safe to write'
        ELSE 'BLOCKED: table is missing — do not let CREATE TABLE IF NOT '
             || 'EXISTS silently recreate it under an old/wrong name'
    END AS guardrail_result
FROM information_schema.tables
WHERE table_schema = 'staging' AND table_name = 'orders_clean';
```

In a notebook/Python driver (the more common real-world shape — see
`pipeline.sql` for the pure-SQL illustration), this becomes a plain
guard clause before the write cell:

```python
target_tables = {"orders_clean", "orders_summary"}
existing_tables = {
    row.tableName for row in spark.sql("SHOW TABLES IN staging").collect()
}
missing_tables = target_tables - existing_tables
if missing_tables:
    raise RuntimeError(
        f"Expected table(s) not found: {missing_tables}. Refusing to let "
        f"CREATE TABLE IF NOT EXISTS silently recreate them — if these "
        f"were intentionally renamed/migrated, update this notebook's "
        f"table names to match before rerunning."
    )
```

Once this guardrail passes, write directly to the real table name — no
`IF NOT EXISTS` clause needed at all for the steady-state case. If a table
genuinely needs first-run bootstrapping, that's a one-time manual setup
step, not something worth keeping a standing silent-recreate escape hatch
around for indefinitely.

## Why This Bites Specifically After a Rename

The failure needs two things to line up, which is exactly why it's easy to
miss in review:

1. A table gets renamed or migrated to a new location as part of some
   cleanup/cutover.
2. Some *other* piece of code — often in a different notebook than the one
   being actively edited during the cutover — still references the table
   by its old name, guarded by `CREATE TABLE IF NOT EXISTS`.

Neither half looks dangerous in isolation. The rename looks like routine
cleanup. The `IF NOT EXISTS` clause looks like harmless defensive coding.
It's only the combination — a stale reference protected by a clause that
turns "table missing" into "silently make a new empty one" instead of an
error — that causes real damage.

## When to Reach for This

- Any time a table gets renamed, and more than one notebook/job/query
  writes to it under its old name — grep for the old name across
  everything in the workspace before considering the rename done, not
  just the notebook you were actively editing.
- Ingestion/ETL jobs where `CREATE TABLE IF NOT EXISTS` was added early on
  purely for first-run convenience and never revisited.
- Any pipeline where "the job succeeded" and "the data is actually
  current" aren't verified as the same thing by anything automated.

## When It's Less Necessary

- Genuinely one-time bootstrap scripts that are deleted/archived right
  after their first successful run — there's no future rename to protect
  against if the code won't exist by the time one happens.
- Tables that are recreated from scratch every run anyway (e.g. `CREATE OR
  REPLACE TABLE ... AS SELECT` reading from a stable upstream source) — the
  risk here is specifically about tables meant to persist and accumulate
  data across runs.

## Verified

Reproduced end-to-end against a live Databricks SQL warehouse using
synthetic data: renamed a table, ran the stale `CREATE TABLE IF NOT
EXISTS` + `INSERT` against the old name, confirmed it silently created an
empty orphaned table and left the renamed table frozen with no error
anywhere. Added the `information_schema.tables` existence guardrail and
confirmed it correctly blocks the write with a clear error when pointed at
a missing/stale table name, and is a silent no-op (just an extra cheap
query) when the table is present and correctly named.
