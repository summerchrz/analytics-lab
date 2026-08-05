-- Databricks notebook source
-- ============================================================================
-- PATTERN: Blended Actuals + Forecast Long-Format Reporting Pipeline
-- ============================================================================
-- Generic, runnable example. Uses only inline synthetic data (VALUES) so it
-- has zero external dependencies -- copy/paste into any Databricks SQL
-- notebook/warehouse and it runs as-is.
--
-- Scenario: a warehouse operations team tracks KPIs (orders shipped, returns,
-- inventory level, utilization) two different ways:
--   1. Two "twin" wide, spreadsheet-style monthly exports coming from two
--      different upstream systems that were each unpivoted independently,
--      by two different people, with two different (and not quite
--      compatible) label conventions.
--   2. A daily event log that needs to be classified and aggregated.
-- Both need to be combined with a separate forecast feed into ONE long-format
-- table, with actuals used up to a cutoff date and forecast used after it.
--
-- This version deliberately preserves two real bugs that show up when this
-- kind of transform is copy-pasted between similar-but-not-identical
-- sources, instead of hiding them behind an idealized "clean" version. See
-- the DBTITLE comments on Steps 1-3 and the pitfalls section in README.md.
-- ============================================================================

-- COMMAND ----------

-- DBTITLE 1,Step 1a: Synthetic wide-format export - SOURCE A (simulates a messy spreadsheet export)
CREATE OR REPLACE TEMP VIEW wide_monthly_kpis_source_a AS
SELECT * FROM VALUES
  ('North',  'Warehouse A', 'Orders Shipped', 2025, 1200.0, 1300.0, 1250.0, 1400.0, 1500.0, 1450.0, 1600.0, 1550.0, 1700.0, 1650.0, 1800.0, 1750.0, 18500.0),
  ('South',  'Warehouse B', 'Orders Shipped', 2025,  900.0,  950.0,  980.0, 1000.0, 1050.0, 1020.0, 1100.0, 1080.0, 1150.0, 1120.0, 1200.0, 1180.0, 12730.0)
AS t(region, warehouse, metric_name, year,
     `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
     `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`, `Value`);
-- `Value` here is an ANNUAL total column that lives in the same wide table as
-- the monthly columns (very common in hand-maintained spreadsheets: someone
-- adds a "YTD" or "Total" column next to the 12 monthly ones). It is NOT a
-- 13th month, but the transform below (mirroring the original code) doesn't
-- know that.

-- COMMAND ----------

-- DBTITLE 1,Step 1b: Synthetic wide-format export - SOURCE B (a "twin" table, different label convention)
CREATE OR REPLACE TEMP VIEW wide_monthly_kpis_source_b AS
SELECT * FROM VALUES
  ('North',  'Warehouse A', 'Returns', 2025,  80.0,  90.0,  85.0,  95.0, 100.0,  98.0, 105.0, 110.0, 115.0, 112.0, 120.0, 118.0, 40.0),
  ('South',  'Warehouse B', 'Returns', 2025,  60.0,  65.0,  70.0,  72.0,  75.0,  74.0,  80.0,  82.0,  85.0,  83.0,  90.0,  88.0, 25.0)
AS t(region, warehouse, metric_name, year,
     `Jan Val`, `Feb Val`, `Mar Val`, `Apr Val `, `May Val`, `Jun Val`,
     `Jul Val`, `Aug Val `, `Sep Val `, `Oct Val `, `Nov Val `, `Dec Val `, `QTY Adj`);
-- Same conceptual shape as Source A (a different team's export of the same
-- kind of monthly data) but NOT the same label convention: "Sep" instead of
-- "Sept", and trailing spaces land on different months entirely. Plus a
-- different-named extra column ("QTY Adj" instead of "Value") that no one
-- updated the mapping logic for.

-- COMMAND ----------

-- DBTITLE 1,Step 2a: Normalize Source A - note the ELSE branch passes the raw label through
-- PATTERN (faithfully reproduced from the original code, including its bug):
-- matching is done on the RAW, non-trimmed label, with a long CASE list and
-- an "ELSE month_label" fallback that lets anything unrecognized flow
-- straight into the date parser instead of failing explicitly.
CREATE OR REPLACE TEMP VIEW actuals_source_a_normalized AS
SELECT
  region, warehouse, metric_name,
  try_to_date(
    concat(
      CASE month_label
        WHEN 'Jan Val ' THEN '01' WHEN 'Feb Val'  THEN '02' WHEN 'Mar Val ' THEN '03'
        WHEN 'Apr Val'  THEN '04' WHEN 'May Val'  THEN '05' WHEN 'Jun Val'  THEN '06'
        WHEN 'Jul Val'  THEN '07' WHEN 'Aug Val'  THEN '08' WHEN 'Sept Val' THEN '09'
        WHEN 'Oct Val'  THEN '10' WHEN 'Nov Val'  THEN '11' WHEN 'Dec Val'  THEN '12'
        WHEN 'Value'    THEN '12' -- BUG (inherited as-is): the annual total
                                   -- column gets treated as if it were
                                   -- December's value and will be SUMMED
                                   -- into the same bucket as the real
                                   -- December figure below.
        ELSE month_label -- BUG (inherited as-is): unrecognized labels are
                          -- not caught here -- they're passed straight into
                          -- try_to_date, which will just return NULL. Any
                          -- future column added to this table with a label
                          -- not in this list disappears silently.
      END,
      ' ', year
    ),
    'MM yyyy'
  ) AS activity_date,
  SUM(TRY_CAST(value AS DOUBLE)) AS total_value,
  'source_a_monthly_export' AS source
FROM wide_monthly_kpis_source_a
UNPIVOT (
  value FOR month_label IN (
    `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
    `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`, `Value`
  )
)
GROUP BY ALL;

-- COMMAND ----------

-- DBTITLE 1,Step 2b: Normalize Source B - same intent, incompatible labels, different ELSE behavior
-- Same transform, written independently against Source B's label convention.
-- Note this ELSE resolves to '0' (a numeric fallback) rather than passing
-- the raw string through -- a DIFFERENT failure mode than Source A's ELSE,
-- even though the two tables are conceptually the same kind of data.
CREATE OR REPLACE TEMP VIEW actuals_source_b_normalized AS
SELECT
  region, warehouse, metric_name,
  try_to_date(
    concat(
      CASE
        WHEN month_label = 'Jan Val'  THEN '01' WHEN month_label = 'Feb Val'  THEN '02'
        WHEN month_label = 'Mar Val'  THEN '03' WHEN month_label = 'Apr Val ' THEN '04'
        WHEN month_label = 'May Val'  THEN '05' WHEN month_label = 'Jun Val'  THEN '06'
        WHEN month_label = 'Jul Val'  THEN '07' WHEN month_label = 'Aug Val ' THEN '08'
        WHEN month_label = 'Sep Val ' THEN '09' WHEN month_label = 'Oct Val ' THEN '10'
        WHEN month_label = 'Nov Val ' THEN '11' WHEN month_label = 'Dec Val ' THEN '12'
        ELSE '0' -- BUG (inherited as-is): unlike Source A, this coerces to a
                 -- syntactically-invalid month ('0' is not a valid 'MM'), so
                 -- try_to_date also returns NULL here -- same silent data
                 -- loss, reached by a different, undocumented code path.
      END,
      ' ', year
    ),
    'MM yyyy'
  ) AS activity_date,
  SUM(TRY_CAST(value AS DOUBLE)) AS total_value,
  'source_b_monthly_export' AS source
FROM wide_monthly_kpis_source_b
UNPIVOT (
  value FOR month_label IN (
    `Jan Val`, `Feb Val`, `Mar Val`, `Apr Val `, `May Val`, `Jun Val`,
    `Jul Val`, `Aug Val `, `Sep Val `, `Oct Val `, `Nov Val `, `Dec Val `, `QTY Adj`
  )
)
GROUP BY ALL;

-- COMMAND ----------

-- DBTITLE 1,Step 3: Synthetic daily event log (a third, differently-shaped actuals source)
CREATE OR REPLACE TEMP VIEW daily_order_events AS
SELECT * FROM VALUES
  ('Warehouse A', DATE'2025-11-03', 'Online',  42, 3),
  ('Warehouse A', DATE'2025-11-15', 'InStore', 18, 1),
  ('Warehouse B', DATE'2025-11-07', 'Online',  30, 2),
  ('Warehouse B', DATE'2025-11-22', 'InStore', 25, 2)
AS t(warehouse, event_date, channel, orders, returns);

-- COMMAND ----------

-- DBTITLE 1,Step 4: Classify + aggregate the event log into the same canonical grain
-- PATTERN: derive a business category via CASE WHEN, then roll up to the same
-- grain (region/warehouse/metric/month) as the other sources so everything
-- can be UNIONed later.
CREATE OR REPLACE TEMP VIEW actuals_from_events AS
SELECT
  CASE warehouse WHEN 'Warehouse A' THEN 'North' ELSE 'South' END AS region,
  warehouse,
  CASE
    WHEN channel = 'Online'  THEN 'Orders Shipped - Online'
    WHEN channel = 'InStore' THEN 'Orders Shipped - InStore'
  END AS metric_name,
  date_trunc('month', event_date) AS activity_date,
  SUM(orders) AS total_value,
  'daily_event_log' AS source
FROM daily_order_events
GROUP BY ALL;

-- COMMAND ----------

-- DBTITLE 1,Step 5: Synthetic forecast feed (already long-format, different source system)
CREATE OR REPLACE TEMP VIEW forecast_kpis AS
SELECT * FROM VALUES
  ('North', 'Warehouse A', 'Orders Shipped', DATE'2025-12-01', 1900.0, 'FCST_2025_11_v2'),
  ('South', 'Warehouse B', 'Orders Shipped', DATE'2025-12-01', 1250.0, 'FCST_2025_11_v2')
AS t(region, warehouse, metric_name, activity_date, total_value, scenario_name);

-- COMMAND ----------

-- DBTITLE 1,Step 6: Blend actuals (before cutoff) with forecast (on/after cutoff) into one canonical schema
-- PATTERN: a single CUTOFF_DATE parameter decides which rows come from
-- actuals vs. forecast. This avoids double-counting and makes the cutoff
-- explicit/auditable in one place instead of scattered across the pipeline.
CREATE OR REPLACE TEMP VIEW params AS
SELECT DATE'2025-12-01' AS cutoff_date, 'FCST_2025_11_v2' AS active_scenario;

CREATE OR REPLACE TABLE blended_kpi_reporting AS
SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_source_a_normalized
WHERE activity_date < (SELECT cutoff_date FROM params)

UNION ALL

SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_source_b_normalized
WHERE activity_date < (SELECT cutoff_date FROM params)

UNION ALL

SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_from_events
WHERE activity_date < (SELECT cutoff_date FROM params)

UNION ALL

SELECT region, warehouse, metric_name, activity_date, total_value, 'forecast' AS source
FROM forecast_kpis
WHERE activity_date >= (SELECT cutoff_date FROM params)
  AND scenario_name = (SELECT active_scenario FROM params);

-- COMMAND ----------

-- DBTITLE 1,Validation 1: confirm no gaps or overlaps around the cutoff
SELECT
  source,
  MIN(activity_date) AS earliest,
  MAX(activity_date) AS latest,
  COUNT(*) AS row_count
FROM blended_kpi_reporting
GROUP BY source
ORDER BY earliest;

-- COMMAND ----------

-- DBTITLE 1,Validation 2: surface the December-inflation bug (annual "Value"/"QTY Adj" column bleeding into month 12)
-- If this transform were correct, December's total_value should be roughly
-- in line with the other months. Instead it's inflated by the full annual
-- figure being added on top of the real December number.
SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM blended_kpi_reporting
WHERE month(activity_date) = 12 AND year(activity_date) = 2025
ORDER BY warehouse, metric_name;

-- COMMAND ----------

-- DBTITLE 1,Validation 3: prove rows are being silently dropped for unrecognized labels
-- Every row here has a NULL activity_date -- meaning it was UNPIVOTed
-- successfully, summed successfully, and then quietly discarded by the
-- WHERE activity_date < cutoff_date filter in Step 6 (NULL comparisons are
-- neither true nor false, so the row just disappears). No error, no warning.
-- Run this BEFORE trusting row counts in blended_kpi_reporting.
SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_source_a_normalized WHERE activity_date IS NULL
UNION ALL
SELECT region, warehouse, metric_name, activity_date, total_value, source
FROM actuals_source_b_normalized WHERE activity_date IS NULL;
-- Expect: the "QTY Adj" column from Source B shows up here (40.0 and 25.0),
-- since it isn't handled by Source B's CASE statement and its ELSE branch
-- ('0') doesn't parse as a valid month.
