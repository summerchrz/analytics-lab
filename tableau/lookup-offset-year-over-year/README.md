# Pattern: `LOOKUP(..., -12)` for Year-over-Year Comparisons

## The Pattern

A common way to build a "this month vs. same month last year" comparison in
Tableau, when your view is a monthly time series, is a table calculation:

```
// "Prior Year Value" calculated field
LOOKUP(SUM([sales_amount]), -12)
```

`LOOKUP` looks *n* rows back (or forward) **within the table calculation's
current partition, in its current sort order** — not by date value. `-12`
means "12 rows back," which only equals "12 months back" if every row
really does represent exactly one month, in date order, with no gaps.

## Why It's Fragile

This works perfectly *until* something changes the shape of the table
calc's partition without anyone touching the formula itself:

- A filter removes a month with no data for one region → every following
  "-12" now points at the wrong month for that region
- Someone adds a "Sort by total descending" to the view → rows are no
  longer in date order, and `-12` now means "12 rows up in whatever order
  the view happens to be sorted," which isn't a time offset at all anymore
- The view is duplicated and re-sorted/re-filtered for a different
  worksheet, and the copy silently produces wrong prior-year numbers with
  no error, warning, or visual difference from a correct one

**The core problem:** `LOOKUP(..., -12)` encodes an assumption (partition =
one row per month, in date order) as an implicit dependency on *how the
worksheet happens to be built right now*, rather than as something the
formula itself guarantees.

## More Robust Alternatives

**Option 1 — Explicit date-based LOD instead of row offset**, when you have
the actual date value available:

```
{ FIXED [year_month_bucket] : SUM([sales_amount]) }
// then compare two explicit date-filtered LOD calcs directly,
// e.g. one for [Current Period] and one for [Current Period - 1 Year],
// rather than relying on row position
```

This ties the "one year ago" logic to an actual date computation, so it's
correct regardless of sort order, added/removed filters, or gaps in the
data.

**Option 2 — if `LOOKUP` is genuinely the right tool** (e.g. a dense,
gap-free daily/monthly series where row order reliably tracks time), at
minimum:
- Set the table calculation's **addressing/partitioning explicitly**
  (Edit Table Calculation → "Specific Dimensions") rather than leaving it
  on "Table (down)" default, so it doesn't silently change if someone
  reorders fields
- Add a visible sanity check (e.g. a "months in view" count) so a broken
  offset is at least noticeable rather than silently wrong

## When to Reach for This Pattern at All

- Genuinely dense, evenly-spaced time series where you've confirmed no
  gaps and controlled the sort/partition explicitly
- A quick, one-off exploratory view where correctness under future edits
  isn't a concern

## When to Avoid It

- Any published/shared dashboard other people will filter, re-sort, or
  duplicate later — the fragility is invisible to whoever inherits it
- Any comparison where the underlying data can have gaps (missing months,
  filtered-out regions, partial current period)

## Note on Verification

Unlike the SQL patterns in this repo, this one wasn't run against a live
Tableau instance (no direct Tableau Desktop/Server access from this
environment) — it reflects standard, documented Tableau table calculation
behavior, not an executed test. Treat the syntax as a starting point to
adapt, not copy-paste-verified output.
