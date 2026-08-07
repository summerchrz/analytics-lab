# Pattern: Duplicated LOD Calc Per Dimension Value

## The Anti-Pattern

You need "total sales for Region X" as of a given date, so you write a
Level of Detail (LOD) calculation:

```
{ FIXED [order_date] :
  SUM(IF [region] = 'North America' AND [status] = 'Confirmed'
      THEN [sales_amount] END)
}
```

Then you need the same thing for Europe. Fastest path: duplicate the
calculated field, change `'North America'` to `'Europe'`. Then APAC. Then a
regional sub-split. A year later you have 10+ calculated fields that are
identical except for one hardcoded string, scattered across the field list
with names like `North America Sales (copy)`, `Europe Sales (copy) (copy)`.

**Why this happens:** it's the fastest way to get a new region's number on
a worksheet *right now*, and each individual copy-paste feels harmless.

**Why it's a problem down the line:**
- Every new region/dimension value means another manual copy + hand-edit,
  not a config change
- If the shared logic needs to change (e.g. add a new `status` value to
  include), it has to be changed identically in every copy — miss one and
  you get a silent, hard-to-spot discrepancy between regions
- The field list becomes unreadable — `(copy) (copy) (copy)` suffixes stack
  up and nobody can tell which one is still in use on a worksheet vs.
  abandoned

## The Fix — Parameterize the Dimension

Instead of one calc per value, use a single calc driven by a Tableau
parameter (or, better, a Set/dimension already on the data source):

```
// Parameter: [Region Parameter] (string, list of valid region values)

{ FIXED [order_date] :
  SUM(IF [region] = [Region Parameter] AND [status] = 'Confirmed'
      THEN [sales_amount] END)
}
```

One calculated field. Adding a new region is a parameter value, not a new
formula. Changing the shared logic (the `status` filter) is one edit, not N.

**If you need all regions visible at once** (e.g. a table with a row per
region, not a parameter-driven single-region view), the better fix is
usually to **stop doing this in Tableau at all** — push the "sum by region"
grouping back into the SQL/view layer as a normal `GROUP BY region`, and let
Tableau just render rows instead of hand-building one calc per row value.
LOD calculations are for when you need a value at a *different* grain than
the view (e.g. "total for the whole region" shown next to a row-level
detail) — not for reproducing a plain aggregation Tableau (or the database)
would already do correctly with a `GROUP BY`.

## When You'll See This

- A report has grown by "just add one more region/product/segment" over
  many small requests, each handled the fastest way in the moment
- The calculated fields list has multiple entries with the same base name
  and `(copy)` suffixes
- Nobody currently maintaining the workbook can confidently say which
  copies are still referenced by a worksheet and which are dead

## When Duplication Is Actually Fine

- A true one-off (a single named exception that will never generalize,
  e.g. "corporate HQ gets its own special rule")
- The dimension values are genuinely fixed and small in number (2-3) and
  extremely unlikely to grow — the parameterization overhead may not be
  worth it for something that will never need a 4th value
- **The workbook is deliberately one dashboard page per dimension value**
  (e.g. one page for North America, one for Europe, one for APAC — not a
  single page where users switch between regions). In this layout, a
  parameter doesn't actually reduce the calc count: you'd either need a
  parameter's worth of calcs per page anyway, or a shared parameter that
  lets users switch dimension values, which defeats the point of a
  dedicated-page-per-value design in the first place. Here, "one calc per
  region" is simply the cost of that layout choice, not copy-paste debt —
  don't recommend parameterizing without first confirming whether the
  workbook is meant to let users switch the dimension dynamically, or is
  intentionally structured as fixed, separate views.

## Note on Verification

Unlike the SQL patterns in this repo, this one wasn't run against a live
Tableau instance (no direct Tableau Desktop/Server access from this
environment) — it reflects standard, documented Tableau LOD/parameter
syntax and behavior, not an executed test. Treat the syntax as a starting
point to adapt, not copy-paste-verified output.
