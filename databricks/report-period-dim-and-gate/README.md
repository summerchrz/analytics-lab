# Report-Period Dim + Fail-Loud Gate

A reusable skeleton for **quarterly (or monthly) refresh jobs**: one reporting-period
parameter drives a dim lookup, and a validation step **fails the run** if the
expected snapshot month is missing upstream — instead of writing a half-empty
workbook and calling it success.

Fully self-contained: `period_gate.sql` uses only inline `VALUES` (synthetic).

## The Pattern

1. **Single knob** — e.g. `report_period = '2026Q2'`. Downstream SQL never hardcodes
   `JUN2026` / run IDs in a dozen places.
2. **Dim table** — maps each report period → operating snapshot label, sort keys,
   calendar attributes. Seed once; extend when a new quarter is added.
3. **Params view** — join widget/param to dim (`period_kind = 'QUARTERLY'`).
4. **Gate checks** — at least:
   - dim row exists for the widget value
   - upstream fact table has rows for that operating month
5. **Fail loud** — if any check fails, stop before staging/Excel writes.

## When to Use This

- Recurring scorecards / pulse decks where “which period?” is the only human input
- Upstream snapshots land on a lag (month-end not available on day 1)
- You would rather a red job than a green job with last-quarter leftovers

## Common Pitfalls / When It Breaks

- **Dim missing the new quarter** — widget accepts `2026Q3` but gate fails on
  `report_period_mapped`. Fix: seed the dim row *before* production day.
- **Upstream month string drift** — dim says `SEP2026`, source uses `Sep-2026`.
  Gate passes or fails depending on join; normalize labels in one place.
- **Bypassing the gate “just to see output”** — defeats the design. If you need a
  dry run before month-end, keep the widget on the **last closed** period and use
  the **next** template shell (dry-run the machine, not incomplete facts).
- **Soft warnings instead of fail** — staging then fills blanks; consumers assume
  the period is closed.

## Files

| File | Role |
|------|------|
| `period_gate.sql` | Synthetic dim + fake upstream + three checks |
| `README.md` | This note |

## Verification

Run `period_gate.sql` in a Databricks SQL warehouse or notebook. Expect:

- Checks for `2026Q2` → all `passed = true`
- Same script with widget `2026Q3` while upstream has no `SEP2026` →
  `operating_month_exists = false`

## Related Ideas

- Cutoff date as a *deliberate* business lock (don’t auto-advance) vs completeness
  checks you *should* automate — different kinds of “hardcoded.”
- Pair with Excel writers that only touch data cells (see
  `python-scripts/openpyxl-chart-face-strip`).
