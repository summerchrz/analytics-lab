-- Pattern: guardrail against CREATE TABLE IF NOT EXISTS silently
-- recreating a table that was renamed/migrated away.
--
-- All names below are generic/synthetic — no real schema, table, or
-- business names from any employer.

-- ============================================================
-- Step 0 — set the scene with synthetic data
-- ============================================================
-- Imagine an ingestion notebook that's run on a schedule. It writes into
-- two "production" tables that a downstream reporting pipeline reads from.

CREATE OR REPLACE TABLE staging.orders_clean_v2 (
    order_id STRING,
    order_date DATE,
    amount DOUBLE
);

INSERT INTO staging.orders_clean_v2 VALUES
    ('A1', DATE'2026-01-01', 100.0),
    ('A2', DATE'2026-01-02', 250.0);

-- ============================================================
-- Step 1 — the bug: CREATE TABLE IF NOT EXISTS after a rename
-- ============================================================
-- Suppose the team later renames `orders_clean_v2` to the "real" name,
-- `orders_clean`, once it's confirmed good:

ALTER TABLE staging.orders_clean_v2 RENAME TO staging.orders_clean;

-- The ingestion notebook's write cell, however, still has the OLD name
-- baked into a `CREATE TABLE IF NOT EXISTS` guard from before the rename
-- (forgotten during the cutover — this is the realistic failure mode,
-- not a contrived one):

CREATE TABLE IF NOT EXISTS staging.orders_clean_v2 (
    order_id STRING,
    order_date DATE,
    amount DOUBLE
);

INSERT INTO staging.orders_clean_v2 VALUES
    ('A3', DATE'2026-01-03', 400.0);

-- What just happened: `orders_clean_v2` no longer existed (it was renamed
-- away in Step 1). `CREATE TABLE IF NOT EXISTS` does NOT error when the
-- table is missing — it just silently creates a brand-new, EMPTY table
-- under that name, and the INSERT lands in that new, disconnected table.
--
-- The real table (`orders_clean`) never gets today's row. There is no
-- error anywhere. Every downstream consumer of `orders_clean` is now
-- silently stale, and every "job succeeded" notification is telling the
-- truth about the wrong table.

SELECT * FROM staging.orders_clean;      -- still just A1, A2 — frozen
SELECT * FROM staging.orders_clean_v2;   -- new orphaned table with A3

-- ============================================================
-- Step 2 — the fix: guardrail before writing
-- ============================================================
-- Instead of trusting `CREATE TABLE IF NOT EXISTS` to mean "set up first
-- time, otherwise no-op," check that the *real* target tables already
-- exist before writing anything, and fail loudly if not. This turns a
-- silent wrong-table write into an immediate, visible error instead.

-- (In SQL alone this has to be a separate assertion query run first; in
-- a notebook/Python driver, this is naturally an `if` + `raise` before
-- the write cell — see the companion note in this pattern's README.)

SELECT
    CASE
        WHEN COUNT(*) = 1 THEN 'OK: orders_clean exists, safe to write'
        ELSE 'BLOCKED: orders_clean is missing — do not let CREATE TABLE '
             || 'IF NOT EXISTS silently recreate it under an old name'
    END AS guardrail_result
FROM information_schema.tables
WHERE table_schema = 'staging' AND table_name = 'orders_clean';

-- Now the write cell targets the real name directly, with no
-- `IF NOT EXISTS` safety net masking a missing/renamed table:

INSERT INTO staging.orders_clean VALUES
    ('A3', DATE'2026-01-03', 400.0);

SELECT * FROM staging.orders_clean; -- A1, A2, A3 — correct, no orphan table created
