"""
Pattern: turning a messy, multi-block BI/OLAP tool export into a tidy table.

Context this generalizes from: a legacy OLAP-style reporting tool (the kind
that plugs into Excel as an add-in and lets you "refresh" a grid against a
live server) exports data in a very specific, human-readable-but-not-
machine-readable shape: several stacked header rows, blank spacer columns,
occasional blank separator rows, and placeholder values marking rows that
aren't real data. None of that is arbitrary — it's just optimized for a
person looking at it in Excel, not for a script reading it.

This file is fully synthetic — no real company data, table names, or exports
involved. It demonstrates the *shape* of the problem and the steps used to
solve it, not any specific business content.
"""

import pandas as pd


def make_synthetic_export_grid() -> pd.DataFrame:
    """
    Builds a small DataFrame that mimics the structure of a real BI-tool
    export grid, entirely with made-up data:

      - Rows 0-4: stacked header labels, spaced two columns apart (columns
        4, 6, 8, 10 hold "Dimension A" / "Dimension B" / "Frequency" /
        "Region" in every header row; the real label only lives in row 4:
        the month names).
      - Row 5: blank separator.
      - Row 6: a redundant "intro" row that repeats the row's own label
        text, but carries no data.
      - Real data rows follow, in blocks of a few rows per line item,
        separated by blank rows.
      - One line item ("Team Alpha") has some rows where the dimension
        column is a literal 0 instead of real text or a true blank -- a
        junk/placeholder row, not real data.
      - Another line item ("Cross-Team Adjustment") legitimately has no
        team classification at all -- sometimes represented as 0,
        sometimes as a true blank -- because it's a calculated measure
        that spans multiple teams, not because anything is wrong with it.
    """
    rows = []

    # Rows 0-3: repeating stacked header labels (columns 6, 8 = month cols)
    for _ in range(4):
        rows.append([None, None, None, None, None, None, "Header", None, "Header"])
    # Row 4: the actual month names
    rows.append([None, None, None, None, None, None, "Jan", None, "Feb"])
    # Row 5: blank separator
    rows.append([None] * 9)
    # Row 6: redundant intro row (label only, no data)
    rows.append(["*Team Alpha Total*", None, "*Team Alpha Total*", None, None, None, None, None, None])

    # Real data block for Team Alpha
    rows.append(["Team AlphaWidgets", None, "Team Alpha", "Widgets", "USD", "Final", "Team Alpha", "Revenue", 1000.0])
    rows.append(["Team AlphaWidgets", None, "Team Alpha", "Widgets", "USD", "Forecast", "Team Alpha", "Revenue", 1000.0])
    rows.append([None] * 9)  # blank separator between line items

    # Junk placeholder rows for Team Alpha (metric column literally 0)
    rows.append(["Team AlphaWidgets", None, "Team Alpha", "Widgets", "USD", "Final", "Team Alpha", 0, None])
    rows.append([None] * 9)

    # Legitimate cross-team calculated row -- team is genuinely blank (NaN)
    rows.append([None, None, None, None, "USD", "Final", None, "Cross-Team Adjustment", 250.0])
    rows.append([None, None, None, None, "USD", "Forecast", None, "Cross-Team Adjustment", 250.0])
    rows.append([None] * 9)

    # Same cross-team measure, but this time the team column is a literal 0
    # instead of blank -- same real meaning, inconsistent representation.
    # This is the situation that causes a mixed str/int/float dtype problem
    # once you try to write it to a system (like Delta) that requires one
    # consistent type per column.
    rows.append([None, None, None, None, "USD", "Final", 0, "Cross-Team Adjustment", 260.0])

    return pd.DataFrame(rows)


def load_export_sheet(raw: pd.DataFrame) -> pd.DataFrame:
    """
    Turns a raw, messy export grid (like the one above) into a tidy table:
    one row per (dimension..., metric, month) combination, with real
    column names and real numeric values.

    Assumes the same column layout as make_synthetic_export_grid():
      col 2 = region, col 3 = region detail, col 4 = currency,
      col 5 = version, col 6 = team, col 7 = metric,
      col 6/8 = month value columns (real files usually have many more,
      spaced two columns apart the same way).
    """
    # Step 1: drop header/blank/intro rows. The metric column (here, col 7)
    # is populated on every real data row and blank on everything else --
    # found by testing this assumption directly against the real export,
    # not assumed up front.
    data_rows = raw[raw[7].notna()]

    # Step 2: name the dimension columns. There's no header row anywhere in
    # the sheet that actually labels these -- the tool's grid layout is
    # fixed, but nothing in the file announces what each column means.
    dimension_names = {
        2: "region",
        3: "region_detail",
        4: "currency",
        5: "version",
        6: "team",
        7: "metric",
    }
    renamed = data_rows.rename(columns=dimension_names)

    # Step 3: name the month columns, then reshape from "one column per
    # month" into "one row per month" -- the same idea as a SQL UNPIVOT,
    # done in pandas via .melt().
    month_names = {6: "Jan", 8: "Feb"}  # a real file would have all 12
    renamed = renamed.rename(columns=month_names)
    tidy = renamed.melt(
        id_vars=["region", "region_detail", "currency", "version", "team"],
        value_vars=list(month_names.values()),
        var_name="month",
        value_name="value",
    )

    # Step 4: force the value column to real numbers. Because it also held
    # header text earlier in the sheet, pandas may have inferred it as
    # dtype "object" rather than a real numeric type -- `errors="coerce"`
    # turns anything that can't convert into a proper missing value instead
    # of crashing, which also gives you a way to *detect* unexpected
    # leftover text (check .isna().sum() before and after, don't just trust it).
    tidy["value"] = pd.to_numeric(tidy["value"], errors="coerce")

    # Step 5: drop the junk placeholder rows -- but only after confirming
    # they really are junk, not real data with a coincidentally-missing
    # value. In the original investigation, every single row with
    # metric == 0 also had a missing value (a 1.0 correlation, checked
    # directly, not assumed) -- that's what justified dropping them here.
    clean = tidy[tidy["metric"] != 0].copy()

    # Step 6: fix inconsistent "missing" representations before they
    # become a write-time error. Some legitimately blank dimension values
    # show up as a literal 0, others as a true NaN -- same real-world
    # meaning, two different representations. Standardize both to one
    # real null, then explicitly cast to pandas' nullable "string" dtype
    # (NOT Python's built-in str() -- str() converts a real missing value
    # into the literal text "<NA>", which is silently wrong; the "string"
    # dtype keeps it as a genuine null).
    text_columns = ["region", "region_detail", "currency", "version", "team"]
    for col in text_columns:
        clean[col] = clean[col].replace(0, pd.NA)
        clean[col] = clean[col].astype("string")

    return clean


if __name__ == "__main__":
    raw = make_synthetic_export_grid()
    result = load_export_sheet(raw)
    print(result)
    print()
    print("Rows with no team classification (legitimate, not junk):")
    print(result[result["team"].isna()])
