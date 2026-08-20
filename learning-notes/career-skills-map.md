# Career & Skills Map (~4 years in)

Personal snapshot of where skills sit today, where they're heading, and what
to prioritize next. Generalized — no employer-specific context. Updated as
the stack grows (Databricks, Python, Power Automate → server, etc.).

## How to read this

- **Levels:** 1 = exposure → 5 = could teach / own production
- **"Senior-adjacent"** here means *some instincts match strong senior
  analytics people* (failure modes, docs, pipeline thinking) — not that every
  skill is senior-level yet
- At **~4 years**, solid **mid-level** with **select senior instincts** is a
  strong position if execution in Python/Spark/orchestration keeps climbing

---

## Profile (one paragraph)

SQL-first analytics practitioner growing into analytics engineering: Excel/VBA
and Tableau for upstream glue and presentation, Databricks/Python for
lakehouse transforms, Power Automate for workflow automation (with server-side
execution planned). Strength is **cross-layer problem solving + distrust of
silent wrong answers**; growth edge is **production pipeline ownership**
(scheduled jobs, tests, monitoring).

---

## Skills map (current)

| Skill | Level | Evidence in this repo / work | 6-mo target |
|---|---|---|---|
| SQL (transforms, grain, joins) | 4–5 | UNPIVOT, UNION alignment, cutoff blending, guardrails | 5 — add tests + incremental models |
| Data modeling / grain | 4 | Snapshot vs event log, dedup keys, trim rollup | 4–5 — explicit models in dbt/Delta |
| Tableau (calcs, LOD) | 4 | Anti-pattern docs, LOOKUP fragility | 4 — push logic to SQL; viz layer only |
| Excel / VBA | 4 | Allocation pipeline, dictionaries, regex tabs | 4 — maintain; migrate hot paths out |
| PowerPoint VBA | 3 | SetTimer countdown, event wiring | 3 — niche portfolio; don't expand |
| Power Automate | 2–3 | Flows in progress; server push planned | 3–4 — one documented server-bound flow |
| Python (pandas, scripting) | 2–3 | Messy export pipeline, field notes on basics | 3–4 — module + tests |
| Databricks / Spark SQL | 2–3 | Runnable patterns, warehouse-verified | 3–4 — Jobs, Delta, incremental |
| Orchestration (Jobs, schedules) | 1–2 | Implied; not fully shown yet | 2–3 |
| Git / portfolio | 3 | analytics-lab, gitleaks, sanitization | 4 — steady cadence |
| Testing / data quality | 3 | Guardrails, deliberate bugs, existence checks | 4 — dbt/GE-style tests |
| Communication / docs | 4–5 | READMEs, learning notes, pattern index | 5 |

**Spike:** cross-tool analytics + quality instinct  
**Gap:** end-to-end production ownership (schedule, test, alert, iterate)

---

## Automation stack (how the pieces fit)

```
┌─────────────────┐     ┌──────────────────┐     ┌─────────────────┐
│ Excel / VBA     │     │ Power Automate   │     │ Server / cloud  │
│ (workbook glue) │ ──► │ (trigger, route, │ ──► │ (scheduled jobs,│
│                 │     │  notify, handoff)│     │  Databricks)    │
└────────┬────────┘     └────────┬─────────┘     └────────┬────────┘
         │                       │                        │
         └───────────────────────┴────────────────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Delta / warehouse layer │
                    └────────────┬────────────┘
                                 │
                    ┌────────────▼────────────┐
                    │ Tableau / reporting     │
                    └─────────────────────────┘
```

**Direction of travel:** less logic trapped in workbooks; more in **scheduled
lakehouse jobs**, with Power Automate as the **orchestration/handoff layer**
(not a second place to hide business rules).

When Power Automate pushes to server:
- Document each flow: trigger, inputs, outputs, failure notification
- Avoid duplicating transform logic already in SQL/Python — Automate should
  **move files, call APIs, start jobs**, not re-implement allocations
- Add a generalized pattern folder when the first server flow is stable
  (e.g. `power-automate/` or `automation/`)

---

## What "senior-adjacent" means (at ~4 years)

| Instinct | Example |
|---|---|
| Distrust silent failures | Renamed-table guardrail; duplicated LOD anti-pattern |
| Pipeline thinking | Allocation VBA chain; blended actuals SQL |
| Document for future you | Pattern READMEs; Python field notes |
| Know where logic belongs | SQL vs Tableau vs Excel tradeoffs |
| Safe public portfolio | Sanitize before GitHub; no raw workbooks |

**Not senior yet (normal):** production Python packages, broad orchestration
ownership, platform SLAs, mentoring at org scale.

---

## Realistic role projection

### Natural next (12–24 months)

- **Analytics Engineer**
- **BI / Analytics Engineer** (Tableau-heavy orgs)
- **Technical Analyst III / Lead** (if AE title doesn't exist)

### Stretch (24–48 months)

- **Senior Analytics Engineer**
- **Analytics platform / data quality lead** (standards, migrations, reviews)

### Less aligned unless pivoting

- ML Engineer / Data Scientist
- Pure infra data engineering (Kafka, k8s-first)

### Trajectory diagram

```
Today (~4 yr)          12 mo                 24–36 mo
─────────────────────────────────────────────────────────
Mid analytics +        Analytics Engineer    Senior AE /
AE-in-training         (scheduled pipelines)  platform lead
```

**Risk if stalled:** "Senior Excel/Tableau person who knows some Databricks" —
employable, but title/pay ceiling vs true AE track.

---

## Priority stack

### Lean into (high ROI)

1. **One end-to-end Databricks job** — ingest → transform → Delta → schedule → alert
2. **Data tests** — unique, not_null, grain checks (dbt or equivalent)
3. **Python as a module** — refactor export script into `src/` + tests
4. **Power Automate → server** — one documented flow that hands off to a job/API, not re-transforms data
5. **Freeze VBA surface** — extract one hot path to Python; keep repo patterns as reference
6. **Portfolio cadence** — ~1 pattern/month with verification note

### Maintain

- SQL depth
- Tableau for delivery
- Domain knowledge (planning, allocation, operational metrics)

### Deprioritize

- New Excel/VBA features (unless blocking job this week)
- More Tableau LOD cleverness — push down to SQL
- More PowerPoint VBA beyond existing timer pattern

---

## Milestones

| When | Proof point |
|---|---|
| **6 mo** | "I own a scheduled Databricks pipeline with tests and docs." |
| **12 mo** | Interview-ready AE story: SQL + Python + Delta + quality + Automate handoff |
| **18 mo** | Led a migration: moved a workbook step to lakehouse |
| **24 mo** | Senior AE (right org) or strong AE II with migration ownership |

---

## How to describe yourself

**Today (~4 years):**  
> Analytics professional across Excel, Tableau, SQL, and growing Databricks/Python automation. Strong on grain, reconciliation, and failure modes; building production pipeline and Power Automate-to-server skills.

**Heading toward:**  
> Analytics engineer who industrializes spreadsheet-era workflows into tested, scheduled lakehouse pipelines — with Automate for orchestration, not duplicate logic.

---

## Review cadence

Revisit this note every **6 months**. Update levels, add links to new pattern
folders, and mark completed milestones. Delete anything that no longer matches
reality — stale career docs are worse than none.
