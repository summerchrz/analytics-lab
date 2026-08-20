# Pattern: Monthly-Tab Allocation Workbook (VBA)

## What It Does

A macro-enabled Excel workbook pattern for fleet/planning-style allocation grids
where each month is a separate worksheet (`JAN 2026`, `MAR 2026`, …). The VBA
automates:

1. **Column visibility** — hide month columns with zero totals on each tab
2. **CSV export** — flatten visible month tabs into a staging `CSV` sheet (optional file save)
3. **Total allocation build** — consolidate line items into `Total Allocation`
4. **Dedup + rollup** — merge duplicate keys, sum quantities, build trim/no-trim views
5. **Adds by month** — pivot summed quantities into a wide month matrix
6. **Tableau bridge** — stamp `SUMIFS` formulas from a `Tableau` lookup sheet, then freeze values

## Workbook Layout (expected sheets)

| Sheet | Role |
|---|---|
| Month tabs (`JAN 2026`, …) | Wide allocation grid per month |
| `CSV` | Flat export staging area |
| `Total Allocation` | Consolidated line items |
| `Total Allocation (No Trim)` | Rollup without `TRIM_KEY` |
| `Adds by Month` | Pool × month matrix output |
| `Tableau` | Lookup source for `Tableau_Input` |

## Named Ranges (configuration)

| Name | Purpose |
|---|---|
| `First_Row`, `Last_Row` | Data row bounds on month tabs |
| `First_Column`, `Last_Column` | Month column bounds |
| `Totals_Row` | Row holding column totals (for hide-zero logic) |
| `Model_Year` | Model year stamped on export rows |
| `Manufacturer` | Manufacturer label (workbook metadata) |
| `Use_Row_SPI` | `Y` = SPI codes come from row labels (GST/SET); else column header (RISK/REPURCHASE) |
| `Alt_Pool_Enabled` | `Y` = pull alternate pool column on total-allocation rows |
| `GST_SPI`, `SET_SPI`, `Risk_SPI`, `Repurchase_SPI` | SPI code values for export |
| `CSV_Save` | File path when saving CSV |
| `Save_Toggle` | `Y` = write CSV file on `GenerateCSV` |
| `Drop_Ship` | Optional lookup range for drop-ship mapping |
| `Manufacturer_Table` | VLookup table for manufacturer names |

Genericized from OEM-specific toggles (e.g. a single manufacturer flag) to
config-driven named ranges so the pattern is reusable.

## Module Map

| Module | Macros |
|---|---|
| `modAllocationColumns` | `HideZeroColumns`, `UnhideColumns` |
| `modAllocationExport` | `GenerateCSV`, `TotalAllocation` |
| `modTableauBridge` | `Tableau_Input`, `Clear_Tableau` |
| `modAllocationDedup` | `Remove_Duplicates` (+ `NormKeyValue`) |
| `modAllocationRollup` | `Build_TotalAllocation_NoTrim`, `Build_AddsByMonth_FromTotalAllocation_SumLines` |
| `modColorFunction` | `ColorFunction` (worksheet UDF for color-based sum/count) |

## Pipeline Order

`TotalAllocation` runs:

```
read month tabs → write Total Allocation
  → Remove_Duplicates
  → Build_AddsByMonth_FromTotalAllocation_SumLines
  → Build_TotalAllocation_NoTrim
```

## Key Techniques

- **Regex sheet filter** — `^(JAN|…|DEC) \d{4}$` limits macros to month tabs only
- **Font color gate** — only black-font (`Color = 0`) cells export (excludes shaded/formula cells)
- **Dictionary dedup** — `Scripting.Dictionary` merges rows; `Del Mo` normalized to `yyyymm`
- **Formula bridge** — `Tableau_Input` writes dynamic `SUMIFS` + `INDEX/MATCH`, then `.Value = .Value`
- **Trim rollup** — `TRIM_KEY` kept for uniqueness in detail; no-trim sheet sums `FINAL_COUNT` without it

## Common Pitfalls

- **Row-offset headers** — export uses `FirstRow - N` offsets; changing grid layout breaks mapping
- **Undeclared `WS_Count`** — removed unused variable in `UnhideColumns`; declare if you extend it
- **`Rows.Count` without worksheet** — clear helpers should use `ws.Rows.Count`, not active sheet
- **Save CSV workbook** — `GenerateCSV` does not close the new workbook after `SaveAs`
- **Tableau range size** — hard-coded `H3:W7001`; resize if lookup grows

## Files

All modules are standard `.bas` — import into a `.xlsm` via VBA editor.
