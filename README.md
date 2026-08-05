# analytics-lab

A personal, company-agnostic collection of SQL patterns, Python scripts, and
learning notes built while growing into analytics engineering (Databricks,
Python, automation) — a companion to Coursera/self-study work.

## Structure

- `sql-patterns/` — generalized, reusable SQL techniques (window functions,
  reconciliation queries, parameterized query patterns, etc.)
- `python-scripts/` — data validation, automation, and analysis scripts
- `databricks/` — notes and examples on Databricks features (jobs, workflows,
  SQL warehouses, notebooks) using synthetic or public sample data only
- `learning-notes/` — write-ups, decision logs, and concepts learned along the way

## Content Rules (read before committing)

This repo must never contain:

- Real company data, table names, schema names, or query results
- Company hostnames, warehouse/cluster IDs, connection strings, or profile names
- Internal business logic tied to a specific employer's systems
- Credentials, tokens, or API keys of any kind

When adapting something learned at work into an example here:

1. Rename tables/columns to generic placeholders (`orders`, `customers`,
   `daily_sales` — not real names)
2. Use synthetic or public sample data (e.g. Kaggle datasets), never real
   exports
3. Describe the *pattern* or *technique*, not the specific business context

## Safety Net

A pre-commit hook (`.githooks/pre-commit`) runs [gitleaks](https://github.com/gitleaks/gitleaks)
against staged changes on every commit, using the ruleset in `.gitleaks.toml`
(secrets + company-specific term detection). A blocked commit means something
flagged needs manual review — don't bypass it.

Hook path is configured via:

```
git config core.hooksPath .githooks
```

**Note:** `core.hooksPath` is a local git config setting — it does **not** travel
with the repo. If you clone this fresh on another machine, re-run the command
above before committing anything.

This is a **defense-in-depth measure, not a substitute for genericizing
content before committing.** Scanners catch known patterns; they won't catch
everything (e.g. a business rule described in plain English with no
recognizable keyword).
