-- Databricks notebook source
-- ============================================================================
-- PROPOSED FIX for pipeline.sql
-- ============================================================================
-- Same scenario, same two "twin" sources -- but this version eliminates both
-- bugs by construction rather than by getting the CASE statements right
-- (which is exactly what failed last time). Three structural changes:
--
--   1. ONE shared label->month lookup table instead of two independently
--      hand-written CASE statements. Adding a new label variant means
--      inserting one row, not editing code in N places.
--   2. Non-monthly columns (annual totals, adjustments) are EXCLUDED from
--      the UNPIVOT list explicitly and handled as their own, honestly-named
--      metric -- never silently folded into a month.
--   3. An explicit "unmapped labels" check runs BEFORE the main transform
--      and fails loudly (via a non-empty result you're expected to check)
--      instead of relying on try_to_date's silent NULL.
-- ============================================================================

-- COMMAND ----------

-- DBTITLE 1,Step 1: Same synthetic sources as pipeline.sql (unchanged, for a fair comparison)
CREATE OR REPLACE TEMP VIEW wide_monthly_kpis_source_a AS
SELECT * FROM VALUES
  ('North',  'Warehouse A', 'Orders Shipped', 2025, 1200.0, 1300.0, 1250.0, 1400.0, 1500.0, 1450.0, 1600.0, 1550.0, 1700.0, 1650.0, 1800.0, 1750.0, 18500.0),
  ('South',  'Warehouse B', 'Orders Shipped', 2025,  900.0,  950.0,  980.0, 1000.0, 1050.0, 1020.0, 1100.0, 1080.0, 1150.0, 1120.0, 1200.0, 1180.0, 12730.0)
AS t(region, warehouse, metric_name, year,
     `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
     `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`, `Value`);

CREATE OR REPLACE TEMP VIEW wide_monthly_kpis_source_b AS
SELECT * FROM VALUES
  ('North',  'Warehouse A', 'Returns', 2025,  80.0,  90.0,  85.0,  95.0, 100.0,  98.0, 105.0, 110.0, 115.0, 112.0, 120.0, 118.0, 40.0),
  ('South',  'Warehouse B', 'Returns', 2025,  60.0,  65.0,  70.0,  72.0,  75.0,  74.0,  80.0,  82.0,  85.0,  83.0,  90.0,  88.0, 25.0)
AS t(region, warehouse, metric_name, year,
     `Jan Val`, `Feb Val`, `Mar Val`, `Apr Val `, `May Val`, `Jun Val`,
     `Jul Val`, `Aug Val `, `Sep Val `, `Oct Val `, `Nov Val `, `Dec Val `, `QTY Adj`);

-- COMMAND ----------

-- DBTITLE 1,Step 2: ONE shared label lookup, covering every variant from every source
-- The fix for "two hand-written CASE statements drift apart": maintain the
-- mapping as DATA, in one place, that every source joins against. Labels are
-- matched after TRIM()ing both sides, so trailing-space inconsistency (the
-- original bug trigger) can't cause a mismatch on its own.
CREATE OR REPLACE TEMP VIEW month_label_lookup AS
SELECT * FROM VALUES
  ('Jan Val', '01'), ('Feb Val', '02'), ('Mar Val', '03'), ('Apr Val', '04'),
  ('May Val', '05'), ('Jun Val', '06'), ('Jul Val', '07'), ('Aug Val', '08'),
  ('Sept Val', '09'), ('Sep Val', '09'),  -- both abbreviation variants, explicitly
  ('Oct Val', '10'), ('Nov Val', '11'), ('Dec Val', '12')
AS t(month_label_trimmed, month_number);

-- COMMAND ----------

-- DBTITLE 1,Step 3: Explicitly separate "true monthly" columns from "annual/adjustment" columns
-- Only the 12 real monthly columns go into UNPIVOT. The extra column is
-- handled on its own with an honest metric name -- it is never a candidate
-- for becoming "December."
-- Note: the UNPIVOT'd column is named `raw_value` (not `value`) specifically
-- to avoid colliding with the `Value` column that still exists on the
-- source table even though it's excluded from this UNPIVOT list.
CREATE OR REPLACE TEMP VIEW actuals_monthly_unpivoted AS
SELECT region, warehouse, metric_name, year, TRIM(month_label) AS month_label_trimmed, TRY_CAST(raw_value AS DOUBLE) AS value, 'source_a' AS src
FROM wide_monthly_kpis_source_a
UNPIVOT (raw_value FOR month_label IN (
  `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
  `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`))
UNION ALL
SELECT region, warehouse, metric_name, year, TRIM(month_label) AS month_label_trimmed, TRY_CAST(raw_value AS DOUBLE) AS value, 'source_b' AS src
FROM wide_monthly_kpis_source_b
UNPIVOT (raw_value FOR month_label IN (
  `Jan Val`, `Feb Val`, `Mar Val`, `Apr Val `, `May Val`, `Jun Val`,
  `Jul Val`, `Aug Val `, `Sep Val `, `Oct Val `, `Nov Val `, `Dec Val `));

CREATE OR REPLACE TEMP VIEW annual_adjustments AS
SELECT region, warehouse, metric_name, year, `Value` AS value, 'source_a' AS src FROM wide_monthly_kpis_source_a
UNION ALL
SELECT region, warehouse, metric_name, year, `QTY Adj` AS value, 'source_b' AS src FROM wide_monthly_kpis_source_b;

-- COMMAND ----------

-- DBTITLE 1,Step 4 (build-time check): fail loudly if any monthly label has no lookup match
-- This should return ZERO rows. If it doesn't, a new/changed label variant
-- has appeared upstream and needs a row added to month_label_lookup -- the
-- pipeline should not proceed silently past this.
SELECT DISTINCT a.month_label_trimmed, a.src
FROM actuals_monthly_unpivoted a
LEFT JOIN month_label_lookup l ON a.month_label_trimmed = l.month_label_trimmed
WHERE l.month_label_trimmed IS NULL;

-- COMMAND ----------

-- DBTITLE 1,Step 5: Normalize using the shared lookup (join, not per-source CASE)
CREATE OR REPLACE TEMP VIEW actuals_monthly_normalized_fixed AS
SELECT
  a.region, a.warehouse, a.metric_name,
  try_to_date(concat(l.month_number, ' ', a.year), 'MM yyyy') AS activity_date,
  SUM(a.value) AS total_value,
  concat(a.src, '_monthly_export') AS source
FROM actuals_monthly_unpivoted a
INNER JOIN month_label_lookup l ON a.month_label_trimmed = l.month_label_trimmed
GROUP BY ALL;

CREATE OR REPLACE TEMP VIEW annual_adjustments_normalized AS
SELECT
  region, warehouse,
  concat(metric_name, ' - Annual Adjustment') AS metric_name,
  make_date(year, 12, 31) AS activity_date, -- honestly labeled as an annual
                                             -- figure dated at year-end, NOT
                                             -- blended into a monthly bucket
  SUM(value) AS total_value,
  concat(src, '_annual_adjustment') AS source
FROM annual_adjustments
GROUP BY ALL;

-- COMMAND ----------

-- DBTITLE 1,Validation: December should now match the real December figure only
SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_monthly_normalized_fixed
WHERE month(activity_date) = 12 AND year(activity_date) = 2025
ORDER BY warehouse, metric_name;
-- Expect: Warehouse A "Orders Shipped" = 1750.0 (not 20250.0), Warehouse B =
-- 1180.0 (not 13910.0). The annual totals now appear separately, below.

-- COMMAND ----------

-- DBTITLE 1,Validation: no rows lost -- the annual/adjustment values are preserved, just correctly labeled
SELECT * FROM annual_adjustments_normalized ORDER BY warehouse, metric_name;
-- Expect: the 18500.0 / 12730.0 / 40.0 / 25.0 values all present here, none
-- of them silently dropped and none of them bleeding into December.
