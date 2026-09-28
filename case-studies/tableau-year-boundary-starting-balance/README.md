# Tableau Year-Boundary Starting Balance

## Problem

A reporting view needed January's opening balance to equal the prior year's December ending balance, while still allowing the current-year view to hide the previous year's monthly detail.

That sounds simple until the previous year is filtered out of the view. Once December disappears from the partition, a row-offset calculation no longer has anything to look back at.

The first attempts also collided with an existing dependency chain:

```
starting balance
    ↓
sales / removals
    ↓
ending balance
    ↓
next period starting balance
```

Trying to define January from December while December itself depended on the same running logic created a circular reference.

## Why this is an interesting analytics problem

This is not really a Tableau syntax problem. It is a **state-transition problem**.

For each month:

```
ending_balance_t = starting_balance_t + additions_t - removals_t
```

and normally:

```
starting_balance_t = ending_balance_(t-1)
```

January crosses a reporting boundary, so the previous row may be intentionally hidden even though its state is still required.

## Fragile approaches

### 1. Row-position lookup

A calculation such as:

```tableau
LOOKUP(SUM([Ending Balance]), -1)
```

works only while the previous month remains in the table-calculation partition.

If the previous year is filtered out first, January has no row to reference.

### 2. Rebuilding the dependency inside the same calculated field

Trying to derive January's start by recomputing December's end inside the start calculation can create circular logic if ending balance already depends on starting balance.

### 3. Parameter filtering too early

A parameter-driven year filter can remove the prior-year data before the calculation executes. The visual looks clean, but the calculation has lost the state it needs.

## Better design options

### Option A: Keep prior-period data available, hide it after the calculation

Use a table-calculation filter or another late-stage display filter so December remains in the partition long enough for January to reference it.

This preserves the sequential model:

```
Dec ending → Jan starting
```

without exposing December in the final visual.

### Option B: Materialize the opening balance upstream

For production reporting, the more robust design is often to calculate the monthly state in SQL before Tableau.

A generalized SQL pattern:

```sql
WITH monthly AS (
    SELECT
        month_start,
        additions,
        removals
    FROM monthly_activity
),
balances AS (
    SELECT
        month_start,
        additions,
        removals,
        SUM(additions - removals)
            OVER (ORDER BY month_start) AS ending_balance
    FROM monthly
)
SELECT
    month_start,
    LAG(ending_balance)
        OVER (ORDER BY month_start) AS starting_balance,
    ending_balance
FROM balances;
```

Now January's opening state exists as a field before Tableau ever filters the view.

### Option C: Persist snapshots

If the opening/ending balance is business-critical, a monthly snapshot table can make the state explicit and auditable instead of reconstructing it repeatedly in the BI layer.

## General lesson

When a dashboard needs a value from data that the user should not see, do not confuse **hidden from the view** with **removed from the calculation context**.

And when a BI calculation begins recreating a state machine, that is a strong signal to consider moving the logic upstream.
