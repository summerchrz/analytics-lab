# When Not to Automate a “Source”

Short decision note from building a quarterly Excel automation: two values can
look equally “hardcoded,” but only one should become a job.

## Two kinds of manual

| Kind | Example shape | Automate? |
|------|---------------|-----------|
| **Mechanical** | “Pick the last month that has non-null actuals” | **Yes** — repeatable rule |
| **Judgment / published lock** | “This chart series is the deck we already showed leadership; live feed can’t reproduce history yet” | **No auto-refresh** — seed or paste until grain exists |

## Smell test

If the live table is a **current book** (recent cohorts only) and the face needs
a **multi-year published series**, computing HHI/share metrics from that table
will produce numbers that look precise and fail an audit.

Prefer:

1. Document the lock in code (`SEED = {...}` + comment)
2. Fail validation when the *period snapshot* is missing (completeness)
3. Do **not** silently fill from the incomplete feed

## Tie-in

- Gate incomplete periods: `databricks/report-period-dim-and-gate`
- Write Excel faces without destroying charts:
  `python-scripts/openpyxl-chart-face-strip`
