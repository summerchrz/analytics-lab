# Recruiter / Hiring Manager Quick Tour

If you only have ten minutes, start here.

## 1. Read the portfolio overview
[PORTFOLIO.md](PORTFOLIO.md)

This explains the through-line across the repository: analytics, automation, debugging, and the move toward analytics engineering.

## 2. Open one SQL / Databricks project
[Blended actuals + forecast pipeline](databricks/blended-actuals-forecast-pipeline)

Why it matters:
- combines differently shaped sources
- reshapes wide data into long format
- normalizes inconsistent labels
- blends historical and forecast logic
- documents real failure modes instead of hiding them

## 3. Open one Python project
[Messy BI export → tidy table](python-scripts/messy-bi-export-to-tidy-table)

Why it matters:
- shows practical pandas cleanup
- handles awkward spreadsheet-style exports
- deals with real null/type behavior before Spark/Delta writes
- demonstrates why "the code runs" is not the same as "the data is safe"

## 4. Read one debugging case study
[Analytics debugging playbook](case-studies/debugging-playbook)

This is the clearest view into how I reason through ambiguous data problems.

## 5. Read one migration case study
[Spreadsheet → analytics engineering](case-studies/analytics-engineering-migration)

This shows the architecture direction behind the toolset.

## 6. See the business-process side
[High-volume payment automation](case-studies/high-volume-payment-automation)

This demonstrates how I approach repetitive operational work: understand the process, automate the repetitive pieces, validate outputs, preserve review points, and reduce recurring manual effort.

---

## Profile in one sentence

Analytics professional growing into analytics engineering, with experience across SQL, Databricks, Python, Tableau, advanced Excel/VBA, Power Automate, APIs, operational analytics, process redesign, and data-quality problem solving.

## What differentiates the portfolio

The repository is intentionally not a gallery of toy exercises.

It focuses on:
- messy source data
- brittle legacy workflows
- silent failure modes
- cross-tool decisions
- migration from manual logic to reusable pipelines
- documentation that explains the reasoning behind the code

## Current development focus

- stronger Python packaging and tests
- scheduled Databricks workflows
- data-quality testing
- orchestration and monitoring
- AI-assisted development with human review
