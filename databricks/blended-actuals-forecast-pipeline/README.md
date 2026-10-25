# Blended Actuals + Forecast Long-Format Reporting Pipeline

A generalized version of a common FP&A / operations reporting pattern: combine
several differently-shaped data sources (a wide spreadsheet export, a daily
event log, a separate forecast feed) into one long-format "single source of
truth" table, using actuals up to a cutoff date and forecast beyond it.

Fully self-contained — `pipeline.sql` uses only inline synthetic data
(`VALUES`), so it runs standalone in any Databricks SQL warehouse or notebook
with no external tables or files required.

**This version intentionally keeps two real bugs from the source material
instead of quietly fixing them** — see "Deliberately Preserved Bugs" below.
The point is to see how ambiguity in upstream data actually propagates
through a transform like this, not to show an idealized version that never
existed.

## The Pattern

1. **Wide-to-long UNPIVOT with label normalization** — real-world spreadsheet
   exports rarely have clean, consistent column names (extra spaces,
   abbreviation mismatches like "Sept" vs "Sep"). Two "twin" sources
   (Source A, Source B) simulate two different teams/systems each unpivoting
   the same *kind* of data with a different, incompatible label convention
   and no shared contract between them.
2. **Category derivation via `CASE WHEN`** — when a third source arrives at a
   different grain (e.g. a daily event log instead of a monthly rollup),
   classify and aggregate it up to the same grain before combining.
3. **Canonical schema alignment** — every source is projected to the exact
   same column set before `UNION ALL`, so downstream consumers don't need to
   know how many source systems feed the table.
4. **Single cutoff-date parameter for actuals/forecast blending** — rather
   than scattering date logic across the pipeline, one `params` view holds the
   cutoff date and active forecast scenario. This makes the actuals/forecast
   boundary auditable in one place and avoids double-counting.
5. **Validation as a first-class step, run against real behavior, not
   assumptions** — three separate validation queries: cutoff boundary
   integrity, a check for suspiciously large values, and an explicit
   NULL-date audit. All three are necessary; none of them would be triggered
   by a schema check or a "does it run" smoke test.

## Deliberately Preserved Bugs

**Bug 1 — an annual total column gets treated as a 13th month.** Source A's
wide table includes a `Value` column (an annual total sitting next to the 12
monthly columns — extremely common in hand-maintained spreadsheets). The
`CASE` statement maps `'Value' -> '12'`, so it gets summed straight into
December. Verified result: Warehouse A's December "Orders Shipped" comes out
as `20250.0` — the real December figure (`1750`) plus the entire annual total
(`18500`) folded in on top of it.

**Bug 2 — the same conceptual column silently vanishes in a sibling table.**
Source B has the equivalent extra column, but it's named `QTY Adj` instead of
`Value`, and nobody updated Source B's `CASE` statement to handle it. It falls
through to `ELSE '0'`, which isn't a valid two-digit month, so
`try_to_date(...)` returns `NULL` — and the row is silently dropped by the
`WHERE activity_date < cutoff_date` filter later on (NULL comparisons are
neither true nor false). Verified result: `QTY Adj` values (`40.0`, `25.0`)
never appear anywhere in `blended_kpi_reporting` — no error, no warning, just
missing data. Validation 3 in `pipeline.sql` surfaces exactly these rows by
checking for `activity_date IS NULL` *before* the cutoff filter runs.

The lesson: **two independently-written normalizations of "the same kind of
column" produced two different failure modes** (silent miscalculation vs.
silent omission) for what was structurally the same underlying problem — an
extra column nobody accounted for. Neither failure throws an error. Both are
only catchable by validating actual output values, not by checking that the
query runs successfully.

## When to Use This

- Multiple systems need to be reconciled into one reporting table
- At least one source arrives in a "wide" or spreadsheet-like shape that needs
  unpivoting
- You need actuals to seamlessly hand off to forecast at a rolling cutoff date
- You want the actuals/forecast boundary to be a single, auditable parameter
  rather than logic duplicated in multiple places

## Common Pitfalls

- **Silent month-label mis-mapping**: if the `CASE` normalization doesn't
  cover every label variant present in the source, rows silently disappear
  (via `NULL` dates) rather than erroring — see Bug 2 above for a concrete,
  verified example. Always run a NULL-date audit, not just a row-count check.
- **"Extra column" columns get UNPIVOTed too**: any non-monthly column left in
  a wide table (annual totals, YTD, adjustments) will get treated as a month
  by an UNPIVOT unless it's excluded up front — see Bug 1 above. Prefer
  explicitly listing only the true monthly columns in `UNPIVOT (... IN (...))`
  over assuming "everything except the known ID columns" is safe.
- **Two "twin" sources drift independently**: when the same kind of
  transformation is written more than once (once per source system), nothing
  keeps them consistent. Consider a single shared normalization function/UDF
  instead of copy-pasting the `CASE` statement per source.
- **Double-counting at the cutoff boundary**: if the actuals filter uses `<=`
  and the forecast filter uses `>=` the same cutoff date, you'll double-count
  that month. Use a consistent, mutually exclusive boundary (`<` / `>=` as
  used here).
- **Scenario drift**: if a forecast table holds multiple scenario versions
  and the active scenario isn't filtered explicitly (as in `params` here),
  you can silently blend rows from stale or superseded forecast runs.

## Verified

Verified end-to-end in Databricks SQL using the inline synthetic data:
- Validation 1: actuals sources end at `2025-11-01`, forecast starts exactly
  at the `2025-12-01` cutoff, no overlapping or missing months.
- Validation 2 / Bug 1: December totals confirmed inflated by the exact
  annual-total amount (`20250.0` and `13910.0`, matching the math above).
- Validation 3 / Bug 2: `QTY Adj` rows (`40.0`, `25.0`) confirmed present with
  `activity_date = NULL`, confirming they never reach the final table.

## `pipeline_fixed.sql` — Proposed Fix (also verified)

Same two sources, same scenario, three structural changes instead of just
"fix the CASE statements":

1. **One shared `month_label_lookup` table** both sources join against,
   instead of two independently hand-written `CASE` statements that can
   drift apart. Adding a new label variant is an `INSERT`, not a code change
   in two places. Labels are matched after `TRIM()`, so whitespace
   inconsistency alone can't cause a silent miss.
2. **Non-monthly columns excluded from `UNPIVOT` explicitly** and handled as
   their own honestly-named metric (`"... - Annual Adjustment"`), dated at
   year-end — never a candidate for silently becoming "December."
3. **An explicit unmapped-label check that runs first** and is meant to be
   asserted as empty before trusting anything downstream, replacing reliance
   on `try_to_date`'s silent `NULL` on failure.

Verified results: `unmapped_count = 0`; December for both warehouses back to
the real monthly figures (`1750.0`, `1180.0`); all four annual/adjustment
values (`18500.0`, `12730.0`, `40.0`, `25.0`) present under their own
metric name — nothing lost, nothing blended into the wrong bucket.

**Trade-off worth naming**: the fixed version requires maintaining the
`month_label_lookup` table as new label variants appear upstream. That's a
real, ongoing cost — but it's a visible, one-place cost instead of an
invisible, N-places one, which is the actual point of the fix.

## Decision Summary

- **Problem**: A real multi-source reporting notebook mixed unpivoting, date
  normalization, business categorization, and actuals/forecast blending
  across many tightly-coupled steps, using source-system-specific tables and
  business rules that couldn't be shared or reused outside their original
  context.
- **Hypotheses considered**: (a) generalize just the UNPIVOT step in
  isolation, (b) generalize just the actuals/forecast blend, (c) rebuild the
  full pipeline shape end-to-end with synthetic data.
- **Evidence**: The techniques are tightly related in practice — the blend
  step depends on having already normalized and unioned the other sources —
  so isolating just one piece would lose the connective logic that makes the
  pattern useful as a template.
- **Chosen solution**: Rebuild the full pipeline shape (steps 1–6) end-to-end
  against synthetic data, preserving the structure but replacing all
  company-specific tables, categories, and identifiers.
- **Alternatives rejected**: Splitting into separate single-purpose examples.
- **Reason rejected**: Would require maintaining multiple smaller files and
  lose the "how these steps fit together" narrative, which is the most
  reusable part of the pattern.
- **Follow-up recommendations**: If reused for a real pipeline, add a
  `MERGE`/idempotency step for reruns, and consider making `cutoff_date` a
  proper job parameter rather than a hardcoded literal in `params`.
