# From Spreadsheet-Era Analytics to Analytics Engineering

## Context

My background spans Excel/VBA, Tableau, SQL, workflow automation, and increasingly Databricks and Python.

That mix is useful because many real analytics systems do not start as clean warehouse models. They grow from spreadsheets, manual exports, BI calculations, macros, and one-off fixes.

The migration challenge is therefore not simply "rewrite everything in Python." It is deciding which logic belongs where.

## Legacy shape

A typical spreadsheet-era workflow looks like:

```
source export
   ↓
manual cleanup
   ↓
Excel formulas / VBA
   ↓
BI extract
   ↓
Tableau calculations
   ↓
presentation
```

This can work for years, but maintenance cost grows quickly.

## Target shape

The direction I prefer is:

```
source
   ↓
staging
   ↓
SQL / Python transformation
   ↓
tested warehouse or Delta table
   ↓
scheduled job
   ↓
Tableau presentation
```

Automation tools should trigger, route, notify, and hand off work rather than becoming a second transformation engine.

## Migration principles

### Move repeated logic first

If the same rule appears in multiple workbooks, dashboards, or copied calculations, it is a good candidate for the data layer.

### Preserve working interfaces

A migration does not need to replace the whole stack at once. Tableau or Excel can continue to consume the new standardized output while the transformation layer improves underneath.

### Add validation before removing the old path

For a period of time, the old and new outputs can be reconciled.

Useful checks:
- total row counts
- unique-key counts
- period totals
- null rates
- duplicate rates
- known boundary periods

### Extract the brittle step, not the familiar step

The highest-value migration target is usually the step most likely to fail silently, not necessarily the step that is easiest to rewrite.

## Portfolio examples that fit this direction

- wide-to-long Databricks transformations
- schema-stable staging
- table rename guardrails
- messy export cleanup in Python
- duplicated Tableau LOD removal
- VBA allocation workflows
- year-boundary state calculations

Together they show a consistent direction: fewer hidden rules in presentation tools and more reusable, testable logic in the data layer.
