# Recruiter / Hiring Manager Quick Tour

If you only have ten minutes, start here.

## 1. Start with the landing page
[README.md](README.md)

It gives the current profile, technical focus, selected impact, and featured work.

## 2. Open the multi-source analytics model
[Multi-source analytics model](case-studies/multi-source-analytics-model)

Why it matters:
- starts from raw operational sources rather than a pre-modeled dataset
- makes grain and source relationships explicit
- separates normalization, modeling, validation, and reporting
- treats reconciliation as part of the design, not an afterthought

## 3. Open one SQL / Databricks project
[Blended actuals + forecast pipeline](databricks/blended-actuals-forecast-pipeline)

Why it matters:
- combines differently shaped sources
- reshapes wide data into long format
- normalizes inconsistent labels
- blends historical and forecast logic
- documents failure modes instead of hiding them

## 4. Open one Python project
[Messy BI export → tidy table](python-scripts/messy-bi-export-to-tidy-table)

Why it matters:
- shows practical pandas cleanup
- handles awkward spreadsheet-style exports
- deals with null/type behavior before Spark / Delta writes
- demonstrates why "the code runs" is not the same as "the data is safe"

## 5. Read one reasoning case study
[Analytics debugging playbook](case-studies/debugging-playbook)

This is the clearest view into how I reason through ambiguous data problems.

## 6. See the business-process side
[High-volume payment automation](case-studies/high-volume-payment-automation)

This demonstrates how I approach repetitive operational work: understand the process, automate the repetitive pieces, validate outputs, preserve review points, and reduce recurring manual effort.

---

## Profile in one sentence

Senior fleet analytics professional working across SQL, Azure Databricks, Python, Tableau, automation, and analytics engineering, with a career foundation in supply chain, regulatory master data, logistics, operations research, and process redesign.

## Career arc

[Career story](CAREER_STORY.md) traces the progression from supply-chain operations and process improvement into data quality, automation, operations research, senior analytics, and analytics-engineering-shaped work.

Selected measurable outcomes include reducing a recurring payment workflow from roughly **80 hours to 10 hours per week**, supporting more than **$1.2M in submitted claims**, and contributing to more than **$100K in operational savings**.

## What differentiates the portfolio

The repository is intentionally not a gallery of toy exercises.

It focuses on:

- messy source data
- multi-source modeling
- brittle legacy workflows
- silent failure modes
- cross-tool decisions
- migration from manual logic to reusable transformations
- documentation that explains reasoning, not only syntax
- AI-assisted development with human validation

## Current development focus

- stronger Python packaging and tests
- scheduled Databricks workflows
- data-quality testing
- orchestration and monitoring
- reusable analytical models
- AI-assisted development with human review
