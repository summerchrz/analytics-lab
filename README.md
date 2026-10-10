# Summer Chrzescian

### Senior Fleet Analyst · Analytics · Automation · Analytics Engineering

I build analytical systems where business logic, data quality, and reporting meet.

My background spans supply chain, regulatory master data, fleet logistics, process automation, operations research, and senior analytics. Today I work across **SQL, Azure Databricks, Python, Tableau, Excel/VBA, APIs, and workflow automation**, with a growing focus on analytics engineering and AI-assisted development.

**[Portfolio overview](PORTFOLIO.md)** · **[10-minute recruiter tour](RECRUITER_GUIDE.md)** · **[Career story](CAREER_STORY.md)** · **[LinkedIn](https://www.linkedin.com/in/summer-c-3623a2121)** · **[Writing portfolio](https://www.clippings.me/summerhc)**

---

## What I do

I am most interested in the space between analysis and engineering:

- turning raw operational tables into reusable analytical models
- combining multiple sources while protecting grain and business meaning
- moving fragile manual or presentation-layer logic upstream
- building validation and reconciliation into workflows
- modernizing spreadsheet and BI processes without breaking the work people rely on
- using AI to accelerate debugging, documentation, and implementation while keeping human validation in the loop

That through-line appears across this repository: understand the process, define the data, isolate the brittle assumption, build a safer version, validate it, and document why it works.

## Current technical focus

**Core:** SQL · Azure Databricks · Python · Tableau · Analytics Engineering  
**Automation:** Excel/VBA · Power Automate · APIs · workflow redesign  
**Data discipline:** transformation · modeling · validation · integration testing · data quality  
**Domain context:** fleet planning · operations research · supply chain · process improvement

## Selected impact

Across my work, I have:

- reduced a recurring payment process from roughly **80 hours to 10 hours per week**
- supported more than **$1.2M in submitted claims**
- contributed to more than **$100K in operational savings**, including **$11K on a single tow**
- built reporting, automation, and analytical workflows used across operational teams

## Featured work

### 🧩 Multi-source analytics model
[case-studies/multi-source-analytics-model](case-studies/multi-source-analytics-model)

A generalized architecture for combining six operational sources into a reusable analytical layer while protecting grain, normalizing fields, and reconciling downstream outputs.

**Shows:** analytics engineering, source integration, SQL / Databricks, grain reasoning, validation, reusable modeling.

### 🔀 Blended actuals + forecast pipeline
[databricks/blended-actuals-forecast-pipeline](databricks/blended-actuals-forecast-pipeline)

Combines differently shaped sources into one reporting structure, blends actuals and forecast around a period cutoff, and documents failure modes instead of hiding them.

**Shows:** Databricks SQL, UNPIVOT, schema alignment, normalization, boundary logic.

### 🧹 Messy BI export → tidy table
[python-scripts/messy-bi-export-to-tidy-table](python-scripts/messy-bi-export-to-tidy-table)

Transforms a spreadsheet-style export into a typed analytical table and explores the null/type problems that can break downstream Spark / Delta writes.

**Shows:** Python, pandas, reshaping, data typing, defensive cleanup.

### 📊 Tableau year-boundary starting balance
[case-studies/tableau-year-boundary-starting-balance](case-studies/tableau-year-boundary-starting-balance)

Explores the deceptively difficult requirement that January's opening value equal December's closing value while prior-year detail remains hidden.

**Shows:** Tableau calculation context, state transitions, circular-dependency avoidance, SQL pushdown decisions.

### ⚙️ Monthly-tab allocation automation
[excel/monthly-tab-allocation-workbook](excel/monthly-tab-allocation-workbook)

A workbook automation pipeline covering month-tab selection, exports, dictionary-based deduplication, allocation rollups, and downstream reporting output.

**Shows:** Excel VBA, workflow automation, reconciliation, legacy-system modernization.

## How I think

| Case study | Focus |
|---|---|
| [Multi-source analytics model](case-studies/multi-source-analytics-model) | grain, source relationships, transformations, reconciliation |
| [Analytics debugging playbook](case-studies/debugging-playbook) | grain, state, filter timing, boundary cases, silent failures |
| [Spreadsheet → analytics engineering migration](case-studies/analytics-engineering-migration) | deciding what to migrate, where logic belongs, reconciliation strategy |
| [High-volume payment automation](case-studies/high-volume-payment-automation) | process redesign, reconciliation, recurring manual-effort reduction |
| [Operational intake workflow](case-studies/operational-intake-workflow) | structured intake, routing, workflow automation |
| [Transport cost and zone modeling](case-studies/transport-cost-zone-modeling) | operational modeling, assumptions, scenario architecture |
| [AI-assisted analytics workflow](case-studies/ai-assisted-analytics-workflow) | AI-assisted problem framing, implementation, validation, Git-based reuse |

## Career arc

```
Supply chain
    ↓
regulatory master data / data quality
    ↓
fleet logistics / process improvement
    ↓
automation / API / VBA
    ↓
operations research / fleet planning
    ↓
SQL + Databricks + Python
    ↓
analytics engineering
```

The tools changed. The core habit did not: understand messy operational systems well enough to make the data more trustworthy and the workflow more maintainable.

## Repository map

- [databricks/](databricks) — lakehouse and Spark SQL patterns
- [python-scripts/](python-scripts) — cleanup, automation, and analysis
- [tableau/](tableau) — BI-layer calculations and anti-patterns
- [excel/](excel) — workbook/VBA automation
- [powerpoint/](powerpoint) — presentation automation
- [sql-patterns/](sql-patterns) — reusable SQL techniques
- [case-studies/](case-studies) — problem → reasoning → solution write-ups
- [ai-building/](ai-building) — AI-assisted development notes
- [learning-notes/](learning-notes) — skills map and technical learning notes

## Working principles

- **Respect the grain.** Many analytics bugs are really grain or join problems wearing a costume.
- **Fail loudly.** A visible error is safer than a plausible wrong number.
- **Put logic where it belongs.** Reporting tools should present data, not become accidental transformation platforms.
- **Prefer reusable patterns to one-off fixes.**
- **Validate across layers.** Source, transformation, and reporting should reconcile.
- **Document assumptions and boundary conditions.**
- **Use AI to accelerate understanding, not replace it.**
- **Sanitize before sharing.**

## Privacy and sanitization

Some ideas in this repository originate from real-world analytical problems. They are rebuilt using generic naming and synthetic or generalized examples.

This repository must never contain real company or customer data, internal table/schema names, credentials, tokens, hostnames, connection strings, confidential business logic, or identifiable screenshots/exports.

A local gitleaks pre-commit hook provides an additional safety check. It is defense in depth, not a substitute for thoughtful sanitization.

---

> I want this portfolio to show that I can take a messy analytical problem, understand its data shape, isolate the brittle assumption, decide where the logic belongs, build a safer version, and explain why it works.
