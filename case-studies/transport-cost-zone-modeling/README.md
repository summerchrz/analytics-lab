# Transport Cost and Zone Modeling

## Context

Some operational analytics problems combine geography, capacity, cost assumptions, and business constraints rather than fitting neatly into a single dashboard calculation.

This case study captures the modeling pattern without exposing any employer-specific inputs.

## Problem

Estimate and compare transportation cost across origin/destination zones using generalized distance, cost, and allocation assumptions.

## Analytical shape

A simplified model can be expressed as:

```
origin
   ↓
zone mapping
   ↓
distance / lane attributes
   ↓
cost assumptions
   ↓
scenario calculation
   ↓
comparison / recommendation output
```

## Key modeling questions

Before calculating anything:

- What is the unit of analysis?
- Is cost per move, per mile, per unit, or per lane?
- Are fixed and variable costs separated?
- What happens when no exact zone match exists?
- Are there minimum charges or thresholds?
- How are missing or ambiguous locations handled?
- Does the output need a point estimate or a range?

## Why this matters

Operational models often become fragile when:
- mappings are hardcoded in multiple places
- cost assumptions are embedded directly in formulas
- geographic categories overlap
- scenario parameters are not separated from calculations

A more maintainable design keeps:
- reference mappings in one table
- assumptions in a parameter layer
- calculations in reusable SQL/Python logic
- presentation in Tableau/Excel

## Portfolio direction

A future fully synthetic version of this case study can include:
- generated origin/destination locations
- configurable zone tables
- per-mile and fixed-cost assumptions
- scenario comparison
- optional Monte Carlo ranges for uncertain costs

That would turn an operational model into a complete reproducible analytics-engineering example.
