# Messy BI-tool export → tidy table (pandas)

## The problem

Some source systems don't give you an API — they give you an Excel export
designed for a person to read, not a script to parse. Classic shape from a
legacy OLAP-style reporting tool (Excel add-in style, "refresh against a
live server"):

- Several stacked header rows instead of one clean header row
- Real column headers only appear once, buried a few rows down — not at
  row 0
- Blank "spacer" columns alternating with real data columns
- Blank separator rows between line-item blocks
- A redundant "intro" row per block that repeats the block's own label but
  carries no data
- Placeholder values (a literal `0`, not a true blank) used inconsistently
  to mark either (a) genuine junk rows, or (b) a real value that's simply
  not classified along one dimension

None of this is a bug in the export — it's just optimized for a human
skimming it in Excel. The work is figuring out, empirically, which rows and
columns are signal vs. noise, rather than assuming a "normal" header row
exists.

## The approach (see `pipeline.py`)

1. **Find the one column that's reliably populated on every real data row**
   (here: the metric name). Use `.notna()` on *that* column to drop
   everything else — headers, blanks, intro rows — in one step. This has to
   be discovered by inspecting the raw grid (`.iloc[...]`, `.value_counts()`
   on candidate columns), not assumed.
2. **Name the dimension and month columns by position**, since there's no
   header row to read names from automatically.
3. **Reshape wide → long with `.melt()`** — the pandas equivalent of a SQL
   `UNPIVOT`. Twelve month columns become one `month` column and one
   `value` column.
4. **Force the value column to numeric with `pd.to_numeric(..., errors="coerce")`.**
   It was inferred as `object` dtype because it also held header text
   earlier in the sheet; coercing turns anything unconvertible into a real
   missing value instead of throwing — but check `.isna().sum()` before and
   after to make sure you're not silently swallowing something that should
   have converted.
5. **Drop placeholder rows — but only after confirming they're really
   junk.** In the real investigation, every row with the placeholder metric
   value also had a missing value (checked directly: a 1.0 correlation
   between the two), which is what justified dropping them. Don't drop rows
   on an assumption; check the correlation first.
6. **Standardize inconsistent "missing" representations before they hit a
   strict downstream type system.** The same real-world "not applicable"
   meaning showed up as *both* a literal `0` and a true blank in the same
   column, depending on which block of the sheet you were in. Left alone,
   this produces a column with a genuine mix of `str` / `int` / `float`
   values — which pandas happily tolerates (`dtype: object`) but a
   columnar/typed system (Delta, Spark, a real database) will reject the
   moment you try to write it.

## The trap that's easy to get wrong: `str` vs. pandas' `"string"` dtype

`.astype(str)` looks like the obvious fix for a mixed-type column, but it's
wrong for one specific reason: Python's built-in `str()` doesn't know about
pandas' missing-value markers. Calling `str()` on a true missing value
(`pd.NA` or `NaN`) converts it into the **literal text** `"<NA>"` or `"nan"`
— a real string, not a null anymore. Every downstream `is null` check
silently stops matching those rows.

`.astype("string")` (pandas' nullable string dtype, lowercase, as a string
argument) does the right thing instead: real values become real text, and
missing values stay genuinely missing. This only matters because the
column had a real mix of types to begin with — for an already-clean
all-text column, `str` vs. `"string"` wouldn't make a visible difference,
which is exactly why the bug is easy to miss until you hit a column that
actually has nulls mixed in.

## Why this matters for the write step, not just the read step

Getting the dtype right isn't a cosmetic pandas detail — it's what
determines whether the write to a typed table succeeds at all. A column
that's a genuine mix of `str`, `int`, and `float` (dtype `object`) will
fail during the pandas → Spark conversion with an Arrow type error, because
Arrow needs one consistent type per column and pandas' `object` dtype
doesn't promise that. Fixing the dtype *before* the conversion — not after
a cryptic Arrow error — is the point of step 6 above.

Separately: most typed/columnar table formats also reject column names with
spaces or other special characters. If you're renaming raw columns to
human-readable names as part of this process (`"Region Detail"`), rename
them to `snake_case` (`region_detail`) at the same time, rather than
discovering the naming rule from a write-time error.

## When to reach for this pattern

- A source system's only usable export is a human-readable spreadsheet with
  no stable header row (OLAP tool add-ins, some legacy BI tools, an ERP's
  "export to Excel" button)
- You're about to write pandas output into a strict, typed destination
  (Delta, a warehouse table) and the source column had *any* history of
  mixed representations for "missing" (blank, 0, `N/A` as text, etc.)

## When it's overkill

If the export already has one clean header row and consistent types per
column, none of steps 1–2 or 6 apply — a plain `pd.read_excel(path)` with
the default header handling is all you need. This pattern exists
specifically for the multi-header, mixed-placeholder case.

## Verification note

The parsing logic and the `str` vs. `"string"` dtype fix in this file mirror
exact steps that were run and confirmed correct against a real 36,000+ row
export (real data, real Databricks environment, not sanitized here) —
including catching the Arrow write error live, diagnosing it back to the
mixed-type dimension columns, and confirming the placeholder-vs-missing-value
correlation was 1.0 before dropping those rows. The synthetic version in
`pipeline.py` above reproduces that same logic and structure faithfully, but
hasn't been independently re-executed in *this* environment (no local Python
interpreter available here) — treat it as a verified transcription of the
technique, not a freshly re-run test.
