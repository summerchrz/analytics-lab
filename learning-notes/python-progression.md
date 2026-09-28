# Python Progression

This note tracks the transition from "I can read some Python" toward "I can use Python as part of an analytics workflow."

## Early stage: syntax and environment

Initial work focused on:
- imports
- variables
- loops
- tuples
- functions
- list operations
- indexing
- Jupyter cell order
- file paths

A useful early debugging lesson came from a simple pandas failure:

```
NameError: name 'pd' is not defined
```

The fix was trivial, but the lesson was bigger: notebook state matters. Code can fail because a dependency was never imported, a cell was run out of order, or the kernel was reset.

## Learning preference

While learning, I deliberately prefer hints and debugging prompts before complete solutions.

That keeps the reasoning work on my side instead of turning practice into copy/paste.

## Next stage: pandas and data cleanup

The progression moved into:
- DataFrames
- CSV and spreadsheet imports
- filtering
- reshaping
- nullable data types
- wide-to-long transformations
- validation before export

The [messy BI export project](../python-scripts/messy-bi-export-to-tidy-table) is the clearest applied example.

## Current direction

Python is becoming the bridge between:
- awkward source files
- repeatable data cleaning
- Databricks / Spark workflows
- automation
- testing
- future API and app work

## What I want to build next

- a small reusable Python package
- unit tests around transformation logic
- configuration rather than hardcoded paths
- logging and clear failure messages
- one end-to-end scheduled workflow
- a lightweight app or interface around an analytical workflow

## Learning record

Formal learning has included data analytics, SQL, Python, pandas, visualization, and capstone work through structured certificate programs alongside practical project work.

The point of this file is not to claim mastery. It is to make the progression visible.
