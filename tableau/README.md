# Tableau Patterns

Focused examples of Tableau calculation design, failure modes, and decisions about when logic should stay in the BI layer versus move upstream.

## Current patterns

- [Duplicated LOD per dimension value](duplicated-lod-per-dimension-value) — why copy-pasted LOD calculations drift and how to consolidate them
- [LOOKUP offset year-over-year](lookup-offset-year-over-year) — why row-position offsets can silently stop matching calendar periods

## Design principle

Tableau is a delivery and analytical tool, but not every transformation belongs in the workbook.

When logic becomes difficult to reuse, validate, document, or maintain, I consider whether it belongs upstream in SQL or Python instead.
