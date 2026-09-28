# Analytics Lab

### Analytics • Automation • Analytics Engineering

A practical portfolio of data transformations, debugging patterns, automation work, and engineering notes built from real analytical problems and rewritten with synthetic or generalized examples.

**[Portfolio overview](PORTFOLIO.md)** · **[10-minute recruiter tour](RECRUITER_GUIDE.md)** · **[LinkedIn](https://www.linkedin.com/in/summer-c-3623a2121)**

---

## What I build

I work across the space between traditional analytics and analytics engineering: SQL and Databricks for data transformation, Python for cleanup and automation, Tableau for delivery, and Excel/VBA for the legacy workflows that still need to work while better systems are being built.

A recurring theme in this repository is moving from manual, fragile, presentation-layer logic toward reusable, testable, documented data workflows.

## Featured work

### 🧩 Blended actuals + forecast pipeline
[databricks/blended-actuals-forecast-pipeline](databricks/blended-actuals-forecast-pipeline)

Combines differently shaped sources into one long-format reporting table, blends actuals and forecast using a date cutoff, and documents intentionally preserved failure modes before showing a safer design.

**Shows:** Databricks SQL, UNPIVOT, schema alignment, label normalization, failure detection.

### 🧹 Messy BI export → tidy table
[python-scripts/messy-bi-export-to-tidy-table](python-scripts/messy-bi-export-to-tidy-table)

Transforms a multi-header spreadsheet-style export into a typed analytical table and explores the pandas null/type problems that can break writes into Spark/Delta.

**Shows:** Python, pandas, reshape logic, data typing, defensive cleanup.

### 🛡️ Renamed-table recreation guardrail
[databricks/renamed-table-recreation-guardrail](databricks/renamed-table-recreation-guardrail)

Demonstrates how valid SQL can silently create an orphan table after a rename, and how to make the failure visible instead.

**Shows:** production-minded SQL, guardrails, failure-mode reasoning.

### 📊 Tableau year-boundary starting balance
[case-studies/tableau-year-boundary-starting-balance](case-studies/tableau-year-boundary-starting-balance)

Explores the deceptively difficult requirement that January's opening value equal December's closing value while prior-year detail remains hidden.

**Shows:** Tableau calculation context, state transitions, circular dependencies, SQL pushdown decisions.

### ⚙️ Monthly-tab allocation automation
[excel/monthly-tab-allocation-workbook](excel/monthly-tab-allocation-workbook)

A workbook automation pipeline covering month-tab selection, exports, dictionary-based deduplication, allocation rollups, and downstream reporting output.

**Shows:** Excel VBA, workflow automation, reconciliation, legacy-system modernization.

## Case studies: how I think

| Case study | Focus |
|---|---|
| [Analytics debugging playbook](case-studies/debugging-playbook) | grain, state, filter timing, boundary cases, silent failures |
| [Spreadsheet → analytics engineering migration](case-studies/analytics-engineering-migration) | deciding what to migrate, where logic belongs, reconciliation strategy |
| [Tableau year-boundary starting balance](case-studies/tableau-year-boundary-starting-balance) | cross-year state, hidden data vs removed data, avoiding circular logic |
| [High-volume payment automation](case-studies/high-volume-payment-automation) | process redesign, reconciliation, recurring manual-effort reduction |
| [Operational intake workflow](case-studies/operational-intake-workflow) | structured intake, routing, workflow automation |
| [Transport cost and zone modeling](case-studies/transport-cost-zone-modeling) | operational modeling, assumptions, scenario architecture |
| [AI-assisted analytics workflow](case-studies/ai-assisted-analytics-workflow) | AI-assisted problem framing, implementation, validation, and Git-based reuse |

## Technical areas

| Area | Examples in this repo |
|---|---|
| **SQL / Databricks** | transforms, snapshots, unpivoting, schema stability, pipeline guardrails |
| **Python** | pandas cleanup, automation scripts, learning-to-production progression |
| **Tableau** | LOD design, table calculations, calculation-context pitfalls |
| **Excel / VBA** | workbook pipelines, allocation logic, exports, automation |
| **Automation** | workflow decomposition, handoffs, reducing manual processing |
| **AI-assisted analytics & development** | problem decomposition, code iteration, validation, documentation, repository workflow |
| **Documentation** | case studies, failure modes, architecture reasoning, learning notes |

## Repository map

- [databricks/](databricks) — lakehouse and Spark SQL patterns
- [python-scripts/](python-scripts) — cleanup, automation, and analysis
- [tableau/](tableau) — BI-layer calculations and anti-patterns
- [excel/](excel) — workbook/VBA automation
- [powerpoint/](powerpoint) — presentation automation
- [sql-patterns/](sql-patterns) — reusable SQL techniques
- [case-studies/](case-studies) — problem-solving and architecture write-ups
- [ai-building/](ai-building) — AI-assisted development notes
- [learning-notes/](learning-notes) — skills map and technical learning notes

## Current direction

I am deliberately growing toward **analytics engineering**: keeping the analytical judgment and visualization context of BI work while moving transformations into SQL/Python, adding tests and guardrails, and building toward scheduled, observable data workflows.

See the evolving [career-skills-map.md](learning-notes/career-skills-map.md) for the current technical roadmap.

## Working principles

- **Respect the grain.** Many analytics bugs are really grain or join problems wearing a costume.
- **Fail loudly.** A visible error is safer than a plausible wrong number.
- **Put logic where it belongs.** Reporting tools should present data, not become an accidental transformation platform.
- **Prefer reusable patterns to one-off fixes.**
- **Document assumptions and boundary conditions.**
- **Use AI to accelerate understanding, not replace it.**
- **Sanitize before sharing.** No company data, schemas, credentials, private business rules, or identifiable internal artifacts belong here.

## Privacy and sanitization

Some ideas in this repository originate from real-world analytical problems. They are rebuilt using generic naming and synthetic/public data.

This repository must never contain real company or customer data, internal table/schema names, credentials, tokens, hostnames, connection strings, confidential business logic, or identifiable screenshots/exports.

A local gitleaks pre-commit hook provides an additional safety check. It is defense in depth, not a substitute for thoughtful sanitization.

---

### Why this repository exists

> I want this portfolio to show that I can take a messy analytical problem, understand its data shape, isolate the brittle assumption, decide where the logic belongs, build a safer version, and explain why it works.