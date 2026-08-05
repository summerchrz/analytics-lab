# Point-in-Time "Active As Of" Count

A pattern for counting active items (fleet units, inventory, subscriptions)
as of a given snapshot date, when the source is a **periodic snapshot table**
rather than an event log.

## The Pattern

```sql
SUM(CASE WHEN add_date < snapshot_date THEN 1 ELSE 0 END) AS active_count
```

This works because a genuine snapshot table already encodes removal as
*absence* — an item that left inventory simply doesn't appear in later
snapshot rows. So the count only needs to check "had it already arrived by
this date," not "had it also not yet left."

## The Assumption That Makes This Correct (and dangerous if wrong)

This formula is only correct because the source is a **snapshot**, not an
**event log**. If your source instead has one persistent row per item with
separate `add_date` / `removed_date` columns (an event-log shape), this same
formula would over-count anything that was later removed, because removed
items don't disappear from an event-log table the way they do from a
snapshot table. In that shape you'd need:

```sql
SUM(CASE WHEN add_date <= snapshot_date
         AND (removed_date IS NULL OR removed_date > snapshot_date)
    THEN 1 ELSE 0 END)
```

**Always confirm which shape your source table actually is before reusing
this formula** — this is exactly the kind of assumption that's obvious to
whoever wrote the original query and invisible to anyone maintaining it
later, which is why it's called out explicitly here rather than left
implicit in the code.

## When to Use This

- Source is refreshed as a full periodic snapshot (daily/monthly), not an
  append-only event log
- You need "active as of date X" counts, potentially segmented by a
  classification (ownership type, business unit, category, etc.)

## Common Pitfalls

- **Using this formula against an event-log source** (see above) — silently
  overcounts.
- **Off-by-one on the comparison operator**: `<` vs `<=` on `add_date`
  determines whether an item added exactly on the snapshot date counts as
  active that same day. Pick one convention and document it — don't leave it
  to be inferred from behavior.
- **Classification computed twice** (once in `SELECT`, once in `GROUP BY`, as
  in this example) — fine for a short `CASE`, but for anything longer, define
  it once in a CTE/subquery and group by the resulting column name instead of
  repeating the expression.
