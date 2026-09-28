# Portfolio Overview

This repository is a curated record of how I solve analytics problems across SQL, Databricks, Python, Tableau, Excel/VBA, automation, and reporting.

The goal is not to collect every script I have ever touched. It is to show the patterns I return to repeatedly:

- move brittle logic out of the presentation layer
- make hidden assumptions explicit
- prefer reproducible transformations over manual fixes
- design for failure detection, not just happy-path execution
- document the reasoning behind a solution, not only the final syntax
- sanitize work-derived ideas into company-agnostic examples

## What this portfolio demonstrates

### 1. Analytics engineering instincts

The Databricks and SQL patterns show how I think about grain, schema stability, long-format reporting, blended actuals/forecast logic, point-in-time state, and silent-failure guardrails.

Featured:
- [Blended actuals + forecast pipeline](databricks/blended-actuals-forecast-pipeline)
- [Schema-stable staging copy](databricks/schema-stable-staging-copy)
- [Renamed-table recreation guardrail](databricks/renamed-table-recreation-guardrail)
- [Point-in-time active count](databricks/point-in-time-active-count)

### 2. Data cleanup and automation

I often work where spreadsheets, exports, and reporting tools meet. The strongest examples are the ones that turn a fragile manual process into a repeatable pipeline.

Featured:
- [Messy BI export to tidy table](python-scripts/messy-bi-export-to-tidy-table)
- [Monthly-tab allocation workbook](excel/monthly-tab-allocation-workbook)
- [Slide-show countdown timer](powerpoint/slide-show-countdown-timer)

### 3. Tableau calculation design

I use Tableau heavily, but I do not assume every calculation belongs there. Several case studies focus on deciding when a calculation should remain in Tableau and when it should be pushed down into SQL.

Featured:
- [Duplicated LOD per dimension value](tableau/duplicated-lod-per-dimension-value)
- [LOOKUP offset year-over-year](tableau/lookup-offset-year-over-year)
- [Year-boundary starting balance case study](case-studies/tableau-year-boundary-starting-balance)

### 4. Debugging and reasoning

A recurring theme in my work is that technically valid code can still produce the wrong answer. I care about identifying the assumption that made the result wrong.

See:
- [Debugging playbook](case-studies/debugging-playbook)
- [Analytics engineering migration case study](case-studies/analytics-engineering-migration)

### 5. Learning in public

I use this repository as a technical lab as well as a portfolio. The learning notes are intentionally honest about what is already strong and what is still being built.

See:
- [Career and skills map](learning-notes/career-skills-map.md)
- [Python + Databricks concepts from a pipeline build](learning-notes/python-databricks-concepts-from-a-data-pipeline-build.md)
- [AI-assisted building notes](ai-building/README.md)

## Current technical direction

I am moving toward analytics engineering: SQL-first transformations, Python for automation and data processing, Databricks for lakehouse workflows, and BI tools for delivery rather than as the primary home of business logic.

The direction of travel is:

```
manual spreadsheet logic
        ↓
repeatable SQL / Python transformation
        ↓
tested warehouse / Delta layer
        ↓
scheduled orchestration
        ↓
Tableau / reporting
```

## Portfolio principles

**Clarity over cleverness.**  
A calculation that future-me can understand is more valuable than a compact expression nobody wants to touch.

**Fail loudly.**  
Silent wrong answers are more dangerous than visible errors.

**Respect grain.**  
Most analytics bugs eventually become grain bugs, join bugs, or time-window bugs.

**Put logic where it belongs.**  
If a transformation is easier to test, reuse, and maintain in SQL or Python, it should probably not live as five duplicated BI calculations.

**Sanitize aggressively.**  
Work-derived ideas are rewritten using generic names and synthetic data before they enter this repository.

## Repository map

| Area | Focus |
|---|---|
| `databricks/` | lakehouse patterns, SQL transforms, schema and pipeline guardrails |
| `python-scripts/` | data cleanup, automation, analysis utilities |
| `tableau/` | calculation design, anti-patterns, BI-layer decisions |
| `excel/` | VBA and spreadsheet automation patterns |
| `powerpoint/` | presentation automation |
| `sql-patterns/` | reusable SQL techniques |
| `case-studies/` | problem → reasoning → solution write-ups |
| `learning-notes/` | skills, concepts, and development notes |
| `ai-building/` | AI-assisted development and repository workflow experiments |

## What I want this repo to prove

Not that I know every tool.

That I can take a messy analytical problem, understand the data shape, find the brittle assumption, decide where the logic belongs, build a safer version, and explain the reasoning clearly.
