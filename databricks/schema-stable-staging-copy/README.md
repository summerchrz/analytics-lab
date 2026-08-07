# Pattern: Schema-Stable Staging Copy

## The Problem

You're building a pipeline on top of a table you don't own — a vendor feed,
another team's export, a legacy system dump, or (the scenario that actually
motivated this pattern) a table sitting in a **personal ad-hoc schema
belonging to someone who has since left the team**. Reading it directly in
every downstream query means:

- Awkward source column names (trailing spaces, inconsistent capitalization)
  leak into every query that touches the data, forever.
- You can't clean anything up on your side without asking the owning
  team/person to change *their* table (often not your call, and if that
  person is gone, not even possible to ask).
- If the owning table changes or disappears — a column gets renamed, a
  refresh schedule changes, permissions tighten, or (worst case) a personal
  schema gets deprovisioned when its owner's account is deactivated — it
  breaks you directly, with no layer of insulation.
- **The "departed owner" case is the urgent version of this problem**: the
  clock is often already running (an account deactivation date, a schema
  cleanup), and nobody may notice a migration is needed until something
  breaks. Treat "someone left and I depend on their personal tables" as a
  trigger to run this pattern proactively, not just for tables you happen to
  be refactoring anyway.

## The Pattern

Before doing any real transformation work, copy the upstream table into a
table **you own**, in your own schema, as an explicit staging step:

```sql
CREATE OR REPLACE TABLE staging.vendor_feed_snapshot
TBLPROPERTIES ('delta.columnMapping.mode' = 'name')
AS
SELECT * FROM external_vendor_feed;
```

Everything downstream reads from `staging.vendor_feed_snapshot`, never from
the upstream table directly. This one indirection layer is the whole point.

## Why `delta.columnMapping.mode = 'name'` Specifically

This is the detail that makes the pattern actually useful, not just a copy.

By default, a Delta table tracks its columns by their **physical position**
in the underlying Parquet files. Renaming or dropping a column means every
data file has to be rewritten to match the new schema — expensive on a large
table, and it blocks other things from writing to the table while it
happens.

Setting `delta.columnMapping.mode = 'name'` switches Delta to track each
column by an internal, name-based ID instead of physical position. Once
that's on, `ALTER TABLE ... RENAME COLUMN` and `... DROP COLUMN` become
cheap, instant **metadata-only** operations — no file rewrite. This means you
can fix a bad column name after the fact instead of building your naming
mistakes in from day one, or living with them forever because a rewrite is
too expensive.

```sql
ALTER TABLE staging.vendor_feed_snapshot RENAME COLUMN `Jan Val ` TO `jan_val`;
```

**Trade-off to know:** column mapping mode has some restrictions/behavior
differences (e.g. certain older Delta clients, `CONVERT TO DELTA`, and some
external tools may not fully support it) — check your platform's current
Delta docs before relying on it in a workload with unusual read paths. In a
typical Databricks-only Delta table, it's low-risk and enabled purely by the
`TBLPROPERTIES` clause shown above.

## When to Reach for This

- **Someone who owned a table you depend on is leaving/has left** — migrate
  proactively rather than waiting for their schema to become inaccessible.
  This is the highest-urgency trigger for this pattern, not just a nice-to-have.
- You're building a pipeline on top of a table another team maintains, and
  you don't control its structure or naming
- The source table has known-awkward column names/labels you don't want
  propagating into every downstream query
- You anticipate needing to rename/restructure columns on your side later
  and don't want that to mean rewriting a large table
- You're migrating from an old table name/location to a new one and want a
  clean, deliberate cutover point (see step 4 in `pipeline.sql`) instead of
  two "current" copies quietly drifting apart

## A Word on "Get By" Fixes

If you're doing this migration under time pressure (e.g. someone's already
gone), it's fine to migrate only what you currently know you depend on and
call it done for now — but treat that as a **known-incomplete state**, not a
finished migration. Explicitly write down (in a README, a decision log,
wherever you already track this) that the source schema may still contain
other tables nobody has migrated yet, so a future reader doesn't mistake
"the thing I depend on is safe" for "everything in that schema is safe." A
quick `information_schema.tables` query against the old schema tells you
immediately whether anything else is still sitting there unmigrated.

## When It's Overkill

- A one-off, throwaway query — the staging indirection only pays off if the
  table gets read repeatedly by more than one downstream thing
- You already own and fully control the source table's schema

## Verified

Ran end-to-end against a live Databricks SQL warehouse: staging table
creation with `delta.columnMapping.mode = 'name'` set, followed by
`ALTER TABLE ... RENAME COLUMN` on the newly-created table, confirmed
successful with no file rewrite delay.
