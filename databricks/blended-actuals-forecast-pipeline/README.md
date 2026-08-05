# Blended Actuals + Forecast Long-Format Reporting Pipeline

A generalized version of a common FP&A / operations reporting pattern: combine
several differently-shaped data sources (a wide spreadsheet export, a daily
event log, a separate forecast feed) into one long-format "single source of
truth" table, using actuals up to a cutoff date and forecast beyond it.

Fully self-contained — `pipeline.sql` uses only inline synthetic data
(`VALUES`), so it runs standalone in any Databricks SQL warehouse or notebook
with no external tables or files required.

## The Pattern

1. **Wide-to-long UNPIVOT with label normalization** — real-world spreadsheet
   exports rarely have clean, consistent column names (extra spaces,
   abbreviation mismatches like "Sept" vs "Sep"). Normalize explicitly with a
   `CASE` mapping that fails loudly (`NULL`) on anything unrecognized, rather
   than silently mis-parsing.
2. **Category derivation via `CASE WHEN`** — when a second source arrives at a
   different grain (e.g. a daily event log instead of a monthly rollup),
   classify and aggregate it up to the same grain before combining.
3. **Canonical schema alignment** — every source is projected to the exact
   same column set before `UNION ALL`, so downstream consumers don't need to
   know how many source systems feed the table.
4. **Single cutoff-date parameter for actuals/forecast blending** — rather
   than scattering date logic across the pipeline, one `params` view holds the
   cutoff date and active forecast scenario. This makes the actuals/forecast
   boundary auditable in one place and avoids double-counting.
5. **Validation as a first-class step** — the last query checks that actuals
   and forecast meet cleanly at the cutoff with no gap or overlap. Always
   include this when doing a blend like this; it's the check that would have
   caught a double-count or a missing month immediately.

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
  (via `NULL` dates) rather than erroring. Always run the validation step and
  check row counts against the source, not just the final output.
- **Double-counting at the cutoff boundary**: if the actuals filter uses `<=`
  and the forecast filter uses `>=` the same cutoff date, you'll double-count
  that month. Use a consistent, mutually exclusive boundary (`<` / `>=` as
  used here).
- **Scenario drift**: if a forecast table holds multiple scenario versions
  and the active scenario isn't filtered explicitly (as in `params` here),
  you can silently blend rows from stale or superseded forecast runs.

## Verified

Ran end-to-end against a live Databricks SQL warehouse. Validation output
confirmed actuals sources end at `2025-11-01` and forecast starts exactly at
the `2025-12-01` cutoff, with no overlapping or missing months.

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
