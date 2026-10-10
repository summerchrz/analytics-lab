# OpenPyXL Chart Face Strip (Data-Only)

When an Excel template already owns chart formatting (colors, gap width,
multi-level categories), automation should **only write the category/value
cells** the chart points at. Recreating the chart object in openpyxl usually
destroys that formatting.

Also covers a second decision: when a live feed cannot reproduce a
**published historical series**, prefer an explicit **locked seed** (or blank
+ paste) over writing plausible but wrong numbers from an incomplete table.

Synthetic demo — no external files required beyond what the script creates.

## The Pattern

1. Template workbook contains the chart; series formula → fixed strip
   (e.g. categories `I1:P1`, values `I2:P2`).
2. Writer clears/writes **only those cells** each run.
3. Do **not** `ws._charts.clear()` / add a new `BarChart` unless you accept
   restyling every cycle.
4. For a second strip (e.g. alternate index), same rule — expand series in
   Excel once so column I is included if the axis should start there.

### Locked seed vs live feed

| Situation | Prefer |
|-----------|--------|
| Live table has full history at the right grain | Compute face values from staging |
| Live table is a *current book* only; deck has a curated multi-year series | **Locked seed** (versioned in code/config) or manual paste |
| Seed and live disagree | Trust the published series until grain is confirmed — don’t “almost” automate |

Automating a completeness check (is September in yet?) is different from
auto-advancing a business-locked series. Don’t confuse the two.

## When to Use This

- Recurring decks fed by an Excel data workbook with hand-styled charts
- Diversity / concentration indices, small KPI strips beside a tall dump
- Any openpyxl pipeline where “the chart looks wrong after AUTO” was the symptom

## Common Pitfalls / When It Breaks

- **Chart series starts at column J** after you add a new first period in I —
  data is right, axis drops the first bar. Fix series refs in the template.
- **Recreate chart to “resize”** — style reset; prefer data-only + template edit.
- **Writing incomplete-feed math into the face** — looks authoritative, fails
  audit against the published deck.
- **Formulas in the strip** — next AUTO overwrite fights the spill; pick one owner.

## Files

| File | Role |
|------|------|
| `write_face_strip.py` | Creates a tiny xlsx, adds a chart, rewrites data only |
| `README.md` | This note |

## Verification

```bash
python write_face_strip.py
```

Opens/saves `_demo_face_strip.xlsx` in the same folder. Re-run: values change,
chart object count stays 1, formatting path untouched.

## Related

- `databricks/report-period-dim-and-gate` — fail before write if the period
  snapshot isn’t upstream yet.
