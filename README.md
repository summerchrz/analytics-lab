# analytics-lab

A personal, company-agnostic collection of SQL patterns, Python scripts, and
learning notes built while growing into analytics engineering (Databricks,
Python, automation) — a companion to Coursera/self-study work.

## Structure

- `sql-patterns/` — generalized, reusable SQL techniques (window functions,
  reconciliation queries, parameterized query patterns, etc.)
- `python-scripts/` — data validation, automation, and analysis scripts
- `databricks/` — notes and examples on Databricks features (jobs, workflows,
  SQL warehouses, notebooks) using synthetic or public sample data only
- `tableau/` — calculation-layer patterns and anti-patterns (LOD
  expressions, table calculations) using generic field/formula examples
- `learning-notes/` — write-ups, decision logs, and concepts learned along the way

## Pattern Index

### Start Here — What Each Pattern Actually Does

**[`databricks/blended-actuals-forecast-pipeline`](databricks/blended-actuals-forecast-pipeline)**
Takes several differently-shaped data sources and merges them into one clean,
long-format reporting table — using real actuals for past months and
forecast numbers for future months, with a single date deciding where the
switch happens. Two wide, spreadsheet-style tables get flattened into rows,
their inconsistent month labels get mapped to real dates, a third daily-log
source gets rolled up to match, and everything lands in one shared table via
`UNION ALL`. This one deliberately keeps two real bugs instead of hiding
them: an annual total column gets mistaken for "December" and inflates it,
and a similarly-purposed column in the sibling table isn't recognized at
all and silently disappears from the output — no error, just missing data.
`pipeline_fixed.sql` shows the proposed correction: one shared lookup table
instead of two mapping rules that can drift apart, non-monthly columns kept
clearly separate, and an explicit check that fails loudly on an unrecognized
label instead of quietly returning nothing.

**[`databricks/lateral-view-stack-unpivot`](databricks/lateral-view-stack-unpivot)**
Shows a second way to turn columns into rows — for when you already have a
handful of calculated numbers (like `SUM(returns)`, `SUM(damaged)`) in one
query and want them as separate rows, rather than unpivoting a whole source
table. Explains when to reach for this instead of `UNPIVOT`, and the main way
it breaks: you tell it how many label/value pairs to expect
(`STACK(3, ...)`), and if that number gets out of sync with what you
actually pass in, the results silently misalign.

**[`databricks/point-in-time-active-count`](databricks/point-in-time-active-count)**
Counts how many items were "active" as of a specific date, using a simple
comparison (`add_date < snapshot_date`) against a table that already stores
one row per item per day. The important catch: this formula only works
because the source table is a true snapshot — an item that leaves inventory
just stops showing up in later rows. If the source were an event log
instead (permanent rows with separate "removed" dates), this same formula
would overcount, since you'd also need to check the item hadn't been removed
yet. Called out explicitly because it's the kind of assumption that's
obvious to whoever wrote it and invisible to whoever inherits it later.

**[`databricks/schema-stable-staging-copy`](databricks/schema-stable-staging-copy)**
Shows the habit of copying a table you don't own (a vendor feed, another
team's export) into your own schema before doing any real work against it —
instead of building every downstream query directly on top of someone
else's table. The key detail is a table property,
`delta.columnMapping.mode = 'name'`, set at copy time: it lets you rename or
drop columns on your copy later as a cheap, instant metadata change instead
of an expensive full-table rewrite, which matters a lot once you want to fix
a bad source column name (like the trailing-space labels in the blended
pipeline pattern above) without breaking every query that already reads it.

**[`tableau/duplicated-lod-per-dimension-value`](tableau/duplicated-lod-per-dimension-value)**
The Tableau-layer version of the "hand-written mapping that drifts" problem:
instead of one calculation that takes a region/segment as an input, someone
copy-pasted a near-identical LOD calculation once per region, each with a
different hardcoded filter value baked in. Works fine until the shared
logic needs to change (now it's N edits, not one) or a region gets missed.
Fix: a single parameter-driven calculation, or — better, if you just need
one row per region — push the aggregation back into the SQL layer instead
of reproducing a `GROUP BY` by hand in Tableau.

**[`tableau/lookup-offset-year-over-year`](tableau/lookup-offset-year-over-year)**
A common way to build "this month vs. same month last year": a table
calculation that looks a fixed number of *rows* back
(`LOOKUP(SUM([x]), -12)`). Explains why that's a row-position offset, not a
real date offset — so it silently breaks the moment a filter, sort change,
or gap makes row position stop lining up with calendar months — and shows
the more robust alternative (explicit date-based LOD comparison instead of
row lookup).

**[`python-scripts/messy-bi-export-to-tidy-table`](python-scripts/messy-bi-export-to-tidy-table)**
Turns a spreadsheet export from a legacy BI/OLAP tool — the kind with
stacked header rows, blank spacer columns, and no single clean header row —
into a tidy, typed table ready to write into Delta/Spark. Walks through
finding the one reliably-populated column to filter on, reshaping
wide-to-long with `.melt()`, and the two write-time traps that actually
matter: a genuinely mixed-type column (some rows `0`, some blank, same
real meaning) will fail an Arrow conversion unless fixed first, and
`.astype(str)` is the wrong fix for that — it silently turns real missing
values into the literal text `"<NA>"` — where pandas' nullable `"string"`
dtype does it correctly.

### Quick Reference

| Pattern | Location | What it demonstrates |
|---|---|---|
| Blended actuals + forecast reporting pipeline | [`databricks/blended-actuals-forecast-pipeline`](databricks/blended-actuals-forecast-pipeline) | Wide-to-long `UNPIVOT` + label normalization, `CASE`-based categorization, canonical schema alignment via `UNION ALL`, actuals/forecast cutoff blending. Includes a deliberately buggy version (annual-column bleed + silent NULL-drop, both verified) and a proposed fixed version (shared lookup table, verified). |
| Unpivoting named measures with `LATERAL VIEW STACK` | [`databricks/lateral-view-stack-unpivot`](databricks/lateral-view-stack-unpivot) | When to use `STACK` vs. `UNPIVOT`; pitfalls of the `STACK(n, ...)` count parameter. |
| Point-in-time "active as of" count | [`databricks/point-in-time-active-count`](databricks/point-in-time-active-count) | Counting active items from a periodic snapshot table; the critical assumption that makes the formula correct (snapshot vs. event-log source shape). |
| Schema-stable staging copy | [`databricks/schema-stable-staging-copy`](databricks/schema-stable-staging-copy) | Staging a copy of a table you don't own with `delta.columnMapping.mode = 'name'` so column renames/cleanup later are cheap metadata operations, not full-table rewrites. Verified against a live warehouse. |
| Duplicated LOD calc per dimension value | [`tableau/duplicated-lod-per-dimension-value`](tableau/duplicated-lod-per-dimension-value) | Anti-pattern: one near-identical LOD calculation copy-pasted per region/segment instead of parameterized. Fix: single parameter-driven calc, or push the aggregation into SQL. |
| `LOOKUP(..., -12)` year-over-year comparison | [`tableau/lookup-offset-year-over-year`](tableau/lookup-offset-year-over-year) | Why row-position table calc offsets silently break under sort/filter changes, and the more robust explicit date-based LOD alternative. |
| Messy BI-tool export → tidy table | [`python-scripts/messy-bi-export-to-tidy-table`](python-scripts/messy-bi-export-to-tidy-table) | Parsing a multi-header, spacer-column spreadsheet export with no stable header row; `.melt()` reshape; the `.astype(str)` vs. `.astype("string")` null-handling trap before writing to Delta/Spark. |

Each pattern folder is self-contained and runnable standalone (inline
synthetic data via `VALUES`, no external tables) and includes a README with
the pattern explanation, when to use it, common pitfalls, and a verification
note confirming it was actually run against a live Databricks SQL warehouse.

## Content Rules (read before committing)

This repo must never contain:

- Real company data, table names, schema names, or query results
- Company hostnames, warehouse/cluster IDs, connection strings, or profile names
- Internal business logic tied to a specific employer's systems
- Credentials, tokens, or API keys of any kind

When adapting something learned at work into an example here:

1. Rename tables/columns to generic placeholders (`orders`, `customers`,
   `daily_sales` — not real names)
2. Use synthetic or public sample data (e.g. Kaggle datasets), never real
   exports
3. Describe the *pattern* or *technique*, not the specific business context

## Safety Net

A pre-commit hook (`.githooks/pre-commit`) runs [gitleaks](https://github.com/gitleaks/gitleaks)
against staged changes on every commit, using the ruleset in `.gitleaks.toml`
(secrets + company-specific term detection). A blocked commit means something
flagged needs manual review — don't bypass it.

Hook path is configured via:

```
git config core.hooksPath .githooks
```

**Note:** `core.hooksPath` is a local git config setting — it does **not** travel
with the repo. If you clone this fresh on another machine, re-run the command
above before committing anything.

This is a **defense-in-depth measure, not a substitute for genericizing
content before committing.** Scanners catch known patterns; they won't catch
everything (e.g. a business rule described in plain English with no
recognizable keyword).
