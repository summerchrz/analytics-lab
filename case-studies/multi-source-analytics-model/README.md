# Multi-Source Analytics Model

## Problem

Operational reporting often starts with several source tables that were designed for different business processes, not for one analytical question.

The challenge is not simply joining tables. It is deciding:

- what the grain of each source actually is
- which records should be treated as authoritative for each field
- how time, status, and category logic should be aligned
- how to avoid duplicate or missing records after joins
- where reusable transformation logic should live
- how to validate the final reporting layer before downstream use

This case study generalizes a real analytical pattern using synthetic source names and no company data.

## Architecture

The model combines six generalized operational sources into one reusable analytical layer:

```
source_a   source_b   source_c
    \        |        /
      normalization
           |
source_d --+-- source_e
           |
        source_f
           |
      modeled layer
           |
 validation / reconciliation
           |
 reporting-ready output
```

The exact business entities, schemas, table names, and internal rules are intentionally omitted.

## Design approach

### 1. Define grain before joining

Each source is documented at its natural grain before any transformation begins.

Examples of possible grains:

- one row per asset
- one row per transaction
- one row per asset and date
- one row per location
- one row per status change

This prevents a common failure mode: a technically valid join that silently multiplies rows.

### 2. Normalize fields upstream

Source-specific labels, dates, keys, and categories are standardized before they reach the reporting layer.

The goal is to avoid duplicating cleanup rules across dashboards or ad hoc analyses.

### 3. Build reusable transformation layers

SQL / Databricks transformations separate:

1. raw source shape
2. normalization
3. business-ready modeling
4. reporting output

Python can support profiling, reconciliation, or exploratory checks where it is the more practical tool.

### 4. Reconcile across sources

Validation focuses on questions such as:

- do source-level counts reconcile after transformation?
- did any join introduce unexpected duplication?
- are records lost because of null or mismatched keys?
- are time-window assumptions consistent?
- do category totals match known source-level controls?

### 5. Fail loudly

A plausible wrong answer is more dangerous than a visible failure.

The design therefore favors explicit checks and documented assumptions over hidden presentation-layer fixes.

## What this demonstrates

- multi-source analytical modeling
- grain and join reasoning
- SQL and Azure Databricks transformations
- reusable reporting-layer design
- cross-source reconciliation
- data validation and quality checks
- analytics engineering judgment
- translating operational rules into maintainable analytical logic

## Privacy note

This case study is intentionally generalized.

It contains no employer data, internal table or schema names, credentials, business-sensitive formulas, customer information, or identifiable operational records.
