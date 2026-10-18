# AI-Assisted Building Lab

This folder documents how I use AI coding tools as part of a real development workflow rather than as a replacement for understanding the code.

## Current workflow

I use AI assistants to help with:

- repository structure
- translating a problem into smaller implementation steps
- debugging unfamiliar syntax
- reviewing patterns for maintainability
- generating synthetic examples from sanitized problem statements
- documentation and README drafts
- comparing alternative designs

## Rules I follow

### 1. No confidential context in public examples

Work-derived problems are generalized before they become portfolio material.

### 2. Keep human ownership of the model

I want to understand:
- what the code assumes
- what one row means
- where state comes from
- what happens when inputs are missing
- how the code fails

If I cannot explain those things, the code is not finished.

### 3. Prefer hints while learning

For skills I am actively building, especially Python, I use AI as a tutor first and an answer generator second.

The goal is to preserve the mental reps that turn syntax into intuition.

### 4. Use version control as the memory

Useful solutions should end up in Git with context around why they exist.

Chat is temporary. A documented repository becomes reusable knowledge.

## How this connects to analytics work

AI is increasingly part of the workflow around analytics, not a separate hobby layer.

I use it to accelerate problem decomposition, code iteration, documentation, synthetic-example generation, and design comparison while keeping data interpretation, validation, and implementation decisions under human review.

See the [AI-assisted analytics workflow case study](../case-studies/ai-assisted-analytics-workflow) for the full pattern.

## What I am building toward

The long-term goal is to use AI tools to accelerate end-to-end analytics engineering work:

```
problem framing
   ↓
schema / grain design
   ↓
SQL / Python implementation
   ↓
tests
   ↓
documentation
   ↓
Git review
   ↓
deployment / orchestration
```

The interesting skill is not prompting. It is knowing what to ask the tool to build, how to inspect the result, and when the design is wrong even if the code runs.
