# Project Guide

Use this guide for any multi-week or end-to-end build added to `analytics-lab`.

## When to use `projects/`

Create a project folder when the work:

- spans multiple weeks or milestones
- uses more than one tool or language
- has its own data flow or architecture
- benefits from tests, validation, or automation
- deserves a project-level README and progress history

Small reusable examples should stay in the relevant technology folder. Reasoning-first write-ups should stay in `case-studies/`.

## Recommended project structure

```
projects/
└── project-name/
    ├── README.md
    ├── data/
    │   └── sample_or_synthetic_data.csv
    ├── src/
    │   └── ...
    ├── tests/
    │   └── ...
    ├── notebooks/
    │   └── ...
    ├── docs/
    │   └── ...
    └── outputs/
        └── ...
```

Not every project needs every folder. Create only what the project actually uses.

## Project README template

Each larger project should explain:

1. **Problem** — what is being solved?
2. **Why it matters** — who or what benefits?
3. **Architecture / workflow** — how do the pieces fit together?
4. **Data** — where did the sample data come from, and what is its grain?
5. **Implementation** — tools, transformations, automation, or logic used
6. **Validation** — how do we know the result is trustworthy?
7. **Failure modes / lessons learned** — what can go wrong?
8. **Next steps** — what remains?
9. **Privacy note** — confirm the public version contains no confidential data or employer-specific artifacts

## Git workflow

For meaningful changes:

```
main
  ↓
feature branch
  ↓
commits
  ↓
pull request
  ↓
review Files changed
  ↓
merge
  ↓
delete branch
```

Suggested branch names:

- `feature/project-name-step-1`
- `fix/project-name-validation`
- `docs/project-name-readme`

Keep commits small enough that the history tells the story of the build.

## For AI-assisted / Cursor work

AI-assisted development is welcome here, but the repository should still show human ownership.

Before merging AI-generated or AI-assisted changes:

- read the diff
- understand the logic
- run or validate the code where possible
- remove unused scaffolding
- document assumptions
- confirm no sensitive information was introduced
- prefer clear code over clever code

Cursor, ChatGPT, or another assistant can help build the project. The final repository should still make sense to a human reviewer without needing the chat that created it.

## Public-safety checklist

Before any project becomes public or merges into `main`, verify:

- [ ] no real employer data
- [ ] no internal table / schema / catalog names
- [ ] no credentials, tokens, URLs, hostnames, warehouse IDs, or connection strings
- [ ] no identifiable screenshots or exports
- [ ] no proprietary formulas or business rules
- [ ] synthetic / public data is clearly labeled
- [ ] README explains what the project demonstrates
- [ ] links and file paths work
