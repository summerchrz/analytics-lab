# Analytics Debugging Playbook

This is the debugging framework I use when a dashboard or data pipeline is technically running but the answer is wrong.

## 1. Define the grain

Before touching syntax, write down what one row means.

Examples:
- one asset per day
- one region per month
- one transaction
- one customer snapshot

If the grain is unclear, joins and aggregations become guesswork.

## 2. Identify the state transition

For metrics that roll forward over time, write the relationship explicitly.

Example:

```
ending = starting + inflow - outflow
next_starting = current_ending
```

This exposes circular references and boundary conditions immediately.

## 3. Check filter timing

Ask whether a filter removes rows before a table calculation, window function, or comparison can use them.

A clean-looking view can still destroy its own calculation context.

## 4. Test the boundary cases first

I check:
- first month of a year
- last month of a year
- missing months
- zero activity
- duplicate keys
- null labels
- renamed fields
- empty source tables

Boundary conditions usually reveal assumptions faster than average cases.

## 5. Look for silent failure modes

The most dangerous failures are often valid code paths:

- unmatched labels mapping to NULL
- `IF NOT EXISTS` recreating an old table name
- duplicated BI calculations drifting apart
- row-offset calculations shifting after filters
- string conversion turning missing values into text
- a join multiplying rows without an error

## 6. Reduce the problem

Build the smallest version that can still fail.

For SQL, that often means inline `VALUES`.

For Tableau, isolate one dimension and one measure.

For Python, shrink the DataFrame to a handful of rows with the problematic types.

## 7. Decide where the fix belongs

Not every problem should be solved in the tool where it was discovered.

A useful rule:

| Problem | Better home |
|---|---|
| repeated business logic | SQL / Python |
| display-only formatting | Tableau |
| data type cleanup | Python / SQL |
| orchestration | workflow tool / job scheduler |
| workbook interaction | VBA, only when necessary |

## 8. Make the assumption visible

A good fix should leave behind documentation, a test, or a guardrail that tells the next person what assumption matters.

The goal is not only to repair the current bug. It is to make the same class of bug harder to reintroduce.
