# Portfolio Overview

This repository is a curated record of how I solve analytics problems across SQL, Azure Databricks, Python, Tableau, Excel/VBA, automation, and reporting.

The goal is not to collect every script I have ever touched. It is to show the patterns I return to repeatedly:

- define the grain before joining data
- move brittle logic out of the presentation layer
- make hidden assumptions explicit
- prefer reproducible transformations over manual fixes
- design for reconciliation and failure detection
- document the reasoning behind a solution, not only the final syntax
- sanitize work-derived ideas into company-agnostic examples

**Quick links:** [Recruiter guide](RECRUITER_GUIDE.md) · [Career story](CAREER_STORY.md) · [LinkedIn](https://www.linkedin.com/in/summer-c-3623a2121)

## What this portfolio demonstrates

### 1. Multi-source analytical modeling

A major current theme is building reporting-ready analytical structures from raw operational sources rather than assuming a clean modeled dataset already exists.

Featured:
- [Multi-source analytics model](case-studies/multi-source-analytics-model)
- [Blended actuals + forecast pipeline](databricks/blended-actuals-forecast-pipeline)
- [Schema-stable staging copy](databricks/schema-stable-staging-copy)
- [Point-in-time active count](databricks/point-in-time-active-count)

### 2. Analytics engineering instincts

The Databricks and SQL patterns show how I think about grain, schema stability, transformation layers, point-in-time state, boundary logic, and silent-failure guardrails.

Featured:
- [Analytics engineering migration](case-studies/analytics-engineering-migration)
- [Renamed-table recreation guardrail](databricks/renamed-table-recreation-guardrail)
- [Debugging playbook](case-studies/debugging-playbook)

### 3. Data cleanup and automation

I often work where spreadsheets, exports, APIs, and reporting tools meet. The strongest examples turn a fragile manual process into a repeatable workflow.

Featured:
- [Messy BI export to tidy table](python-scripts/messy-bi-export-to-tidy-table)
- [Monthly-tab allocation workbook](excel/monthly-tab-allocation-workbook)
- [High-volume payment automation](case-studies/high-volume-payment-automation)
- [Operational intake workflow](case-studies/operational-intake-workflow)

### 4. Tableau calculation design

I use Tableau heavily, but I do not assume every calculation belongs there. Several examples focus on deciding when a calculation should remain in Tableau and when it should move upstream.

Featured:
- [Duplicated LOD per dimension value](tableau/duplicated-lod-per-dimension-value)
- [LOOKUP offset year-over-year](tableau/lookup-offset-year-over-year)
- [Year-boundary starting balance](case-studies/tableau-year-boundary-starting-balance)

### 5. AI-assisted analytics

AI tools are part of how I build, debug, document, and generalize analytical work, but they do not replace validation or ownership of the underlying model.

Featured:
- [AI-assisted analytics workflow](case-studies/ai-assisted-analytics-workflow)
- [AI-assisted building notes](ai-building/README.md)

### 6. Learning in public

I use this repository as a technical lab as well as a portfolio. The learning notes are intentionally honest about what is already strong and what is still being built.

See:
- [Career and skills map](learning-notes/career-skills-map.md)
- [Python + Databricks concepts from a pipeline build](learning-notes/python-databricks-concepts-from-a-data-pipeline-build.md)
- [Python progression](learning-notes/python-progression.md)

## Current technical direction

I am growing toward analytics engineering while keeping the operational judgment and visualization context that came from analytics work.

The direction of travel is:

```
raw operational sources
        ↓
normalization / transformation
        ↓
reusable analytical model
        ↓
validation / reconciliation
        ↓
Tableau / reporting / decision support
```

## Portfolio principles

**Clarity over cleverness.**  
A calculation future-me can understand is more valuable than compact logic nobody wants to touch.

**Fail loudly.**  
Silent wrong answers are more dangerous than visible errors.

**Respect grain.**  
Many analytics bugs eventually become grain, join, or time-window bugs.

**Put logic where it belongs.**  
If a transformation is easier to test, reuse, and maintain in SQL or Python, it should probably not live as duplicated BI calculations.

**Validate across layers.**  
Source, transformation, and reporting outputs should reconcile.

**Sanitize aggressively.**  
Work-derived ideas are rewritten using generic names and synthetic or generalized examples before they enter this repository.

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

That I can take a messy analytical problem, understand the data shape, define the grain, find the brittle assumption, decide where the logic belongs, build a safer version, validate it, and explain the reasoning clearly.
