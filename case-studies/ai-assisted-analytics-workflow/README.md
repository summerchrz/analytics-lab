# AI-Assisted Analytics Workflow

## Why this belongs in an analytics portfolio

AI is most useful to me when it accelerates an analytical workflow without taking ownership of the reasoning.

The pattern is not:

```
prompt → accept answer
```

It is:

```
problem
  ↓
human framing
  ↓
AI-assisted exploration / implementation
  ↓
human validation
  ↓
version-controlled result
  ↓
documented reusable pattern
```

## Where AI fits

I use AI-assisted tools for work such as:

- breaking large analytics problems into smaller implementation steps
- exploring SQL, Python, Tableau, and automation alternatives
- accelerating documentation and repository structure
- reviewing code for brittle assumptions
- translating known business logic into generalized technical patterns
- generating synthetic examples that preserve a problem without exposing private data
- debugging and comparing implementation approaches
- turning solved problems into reusable GitHub documentation

## Where AI does not replace judgment

Before I consider an AI-assisted result complete, I still need to understand:

- the grain of the data
- the source and meaning of each field
- calculation dependencies
- join behavior
- null and duplicate behavior
- boundary conditions
- what would make the result silently wrong
- whether the logic belongs in SQL, Python, Tableau, VBA, or an orchestration layer

## Example workflow

A typical analytics problem might start as a dashboard calculation that is becoming difficult to maintain.

### 1. Frame the real problem

Instead of asking AI to "fix the calculation," I first identify the state transition, filter context, grain, or upstream transformation that is creating the issue.

### 2. Explore alternatives

AI can help compare options such as:

- Tableau calculation
- SQL window function
- Python transformation
- snapshot table
- parameterized configuration

### 3. Reduce to a safe example

The real problem is rewritten using generic fields and synthetic data.

### 4. Implement and inspect

The generated or assisted code is reviewed for assumptions, edge cases, and silent failure modes.

### 5. Preserve the learning

Once the pattern is understood, it goes into Git with the reasoning documented alongside the code.

## AI + analytics engineering

The direction I am building toward is an AI-assisted engineering workflow where AI speeds up execution across the lifecycle:

```
problem framing
   ↓
data / grain design
   ↓
SQL or Python build
   ↓
tests and validation
   ↓
documentation
   ↓
Git review
   ↓
scheduled workflow
```

The differentiator is not simply access to AI tools. It is the ability to combine them with analytical judgment, domain knowledge, validation, and maintainable engineering practices.

## Portfolio safety rule

AI does not change the sanitization standard.

No confidential data, internal schemas, credentials, proprietary screenshots, identifiable exports, or employer-specific logic should enter a public portfolio example.
