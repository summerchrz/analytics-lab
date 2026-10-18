# Analytics Lab

A public portfolio of analytics engineering, automation, data modeling, debugging, and workflow modernization built from synthetic or generalized examples.

This repository is where I keep the technical proof behind my broader career story: SQL and Azure Databricks for transformation, Python for cleanup and automation, Tableau for delivery, Excel/VBA and Power Automate for legacy and workflow modernization, and GitHub for versioned development.

**Start here:** [Portfolio overview](PORTFOLIO.md) · [Recruiter guide](RECRUITER_GUIDE.md) · [Career story](CAREER_STORY.md) · [Detailed pattern index](PATTERN_INDEX.md)

---

## Featured work

### 🧩 Multi-source analytics model
[case-studies/multi-source-analytics-model](case-studies/multi-source-analytics-model)

A generalized architecture for combining six operational sources into a reusable analytical layer while protecting grain, normalizing fields, and reconciling downstream outputs.

**Shows:** analytics engineering · SQL / Databricks · grain reasoning · validation · reusable modeling

### 🔀 Blended actuals + forecast pipeline
[databricks/blended-actuals-forecast-pipeline](databricks/blended-actuals-forecast-pipeline)

Combines differently shaped sources into one reporting structure, blends actuals and forecast around a period cutoff, and documents failure modes instead of hiding them.

**Shows:** Databricks SQL · UNPIVOT · schema alignment · normalization · boundary logic

### 🧹 Messy BI export → tidy table
[python-scripts/messy-bi-export-to-tidy-table](python-scripts/messy-bi-export-to-tidy-table)

Transforms a spreadsheet-style export into a typed analytical table and documents the null/type issues that can break downstream writes.

**Shows:** Python · pandas · reshaping · data typing · defensive cleanup

### 📊 Tableau year-boundary starting balance
[case-studies/tableau-year-boundary-starting-balance](case-studies/tableau-year-boundary-starting-balance)

Explores the requirement that January's opening value equal December's closing value while prior-year detail remains hidden.

**Shows:** Tableau calculation context · state transitions · circular-dependency avoidance · SQL pushdown decisions

### ⚙️ High-volume payment automation
[case-studies/high-volume-payment-automation](case-studies/high-volume-payment-automation)

Documents the redesign of a recurring manual payment workflow into a more repeatable, reviewable process.

**Shows:** process redesign · reconciliation · automation · measurable manual-effort reduction

---

## Repository structure

| Area | Purpose |
|---|---|
| [projects/](projects) | multi-week or end-to-end builds that combine several tools |
| [case-studies/](case-studies) | problem → reasoning → solution write-ups |
| [databricks/](databricks) | SQL / lakehouse transforms, schema patterns, and guardrails |
| [python-scripts/](python-scripts) | data cleanup, automation, and analysis utilities |
| [tableau/](tableau) | BI-layer calculations and anti-patterns |
| [excel/](excel) | workbook / VBA automation |
| [powerpoint/](powerpoint) | presentation automation |
| [sql-patterns/](sql-patterns) | reusable SQL techniques |
| [ai-building/](ai-building) | AI-assisted development and repository workflow notes |
| [learning-notes/](learning-notes) | skills, concepts, and technical learning notes |

For detailed descriptions of the smaller reusable patterns, see [PATTERN_INDEX.md](PATTERN_INDEX.md).

---

## Where new work goes

This repo now separates **patterns**, **case studies**, and **projects**:

- Use a technology folder such as `databricks/` or `python-scripts/` for a focused reusable technique.
- Use `case-studies/` when the main value is the reasoning, architecture decision, or debugging story.
- Use `projects/` for longer builds that combine multiple tools, files, stages, or weeks of work.

The upcoming multi-week automation project should live under `projects/` so it can grow without crowding the smaller pattern library.

See [PROJECT_GUIDE.md](PROJECT_GUIDE.md) before starting a larger build.

---

## Working principles

- **Respect the grain.** Many analytics bugs are really grain or join problems wearing a costume.
- **Fail loudly.** A visible error is safer than a plausible wrong number.
- **Put logic where it belongs.** Reporting tools should present data, not become accidental transformation platforms.
- **Prefer reusable patterns to one-off fixes.**
- **Validate across layers.** Source, transformation, and reporting should reconcile.
- **Document assumptions and boundary conditions.**
- **Use AI to accelerate understanding, not replace it.**
- **Sanitize before sharing.**

---

## Public-safety rules

This repository must never contain:

- real company or customer data
- internal table, schema, catalog, or system names
- credentials, tokens, hostnames, warehouse / cluster IDs, or connection strings
- proprietary business rules or identifiable screenshots / exports
- code copied directly from an employer environment without sanitization

When adapting a work-derived idea, rebuild the pattern with generic names and synthetic or public data.

A local gitleaks pre-commit hook provides an additional safety check. It is defense in depth, not a substitute for thoughtful sanitization.

---

> I want this portfolio to show that I can take a messy analytical problem, understand its data shape, define the grain, find the brittle assumption, decide where the logic belongs, build a safer version, validate it, and explain why it works.
