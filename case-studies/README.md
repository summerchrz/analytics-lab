# Case Studies

These case studies focus on **how I reason through analytical and workflow problems**, not on reproducing employer systems.

They are intentionally generalized and use no confidential data, internal schemas, credentials, or identifiable operational artifacts.

## Analytics engineering and data design

- [Multi-source analytics model](multi-source-analytics-model) — grain, source relationships, reusable transformations, reconciliation
- [Analytics engineering migration](analytics-engineering-migration) — deciding what logic belongs in spreadsheets, BI, SQL, or Python
- [Analytics debugging playbook](debugging-playbook) — grain, state, filter timing, boundary cases, silent failures
- [Tableau year-boundary starting balance](tableau-year-boundary-starting-balance) — cross-period state and calculation-context design

## Automation and workflow design

- [High-volume payment automation](high-volume-payment-automation) — process redesign, validation, reconciliation, manual-effort reduction
- [Operational intake workflow](operational-intake-workflow) — structured intake, routing, exception handling, workflow automation
- [AI-assisted analytics workflow](ai-assisted-analytics-workflow) — AI-assisted problem framing, implementation, review, and validation

## Operational modeling

- [Transport cost and zone modeling](transport-cost-zone-modeling) — generalized geography, cost, capacity, and scenario modeling

## How to read these

A case study is strongest when it makes five things clear:

1. What problem shape made the work difficult?
2. What assumptions or grain mattered?
3. Where should the logic live?
4. How should the result be validated?
5. What would fail silently if nobody checked?

For runnable code examples, see the technology folders in the repository root.
