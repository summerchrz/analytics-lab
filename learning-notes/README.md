# Learning Notes

Write-ups, decision logs, and concepts learned while growing into analytics
engineering — generalized so no company-specific context is required to
understand them.

## Notes

- [`career-skills-map.md`](career-skills-map.md) —
  Personal skills levels, senior-adjacent instincts, role projection (~4 years
  in), priority stack, and how Excel / Power Automate / Databricks fit together
- [`when-not-to-automate-a-source.md`](when-not-to-automate-a-source.md) —
  Mechanical hardcodes (automate) vs judgment/published locks (don’t
  auto-refresh from an incomplete feed)
- [`python-databricks-concepts-from-a-data-pipeline-build.md`](python-databricks-concepts-from-a-data-pipeline-build.md) —
  Python indentation/block-scoping, list comprehensions, `lambda` +
  `max(key=...)`, single-responsibility functions, pandas' nullable
  `'Int64'` dtype, matching a DataFrame's inferred type to a strict
  destination schema, multi-line method chain continuation, and
  platform-specific path prefixes — all surfaced while building a real
  Excel-to-Delta ingestion function.
