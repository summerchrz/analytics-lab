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
--   1. A wide, spreadsheet-style monthly export (one column per month, with
--      messy/inconsistent month labels -- a very common real-world mess).
--   2. A daily event log that needs to be classified and aggregated.
-- Both need to be combined with a separate forecast feed into ONE long-format
-- table, with actuals used up to a cutoff date and forecast used after it.
-- ============================================================================

-- COMMAND ----------

-- DBTITLE 1,Step 1: Synthetic wide-format monthly actuals (simulates a messy spreadsheet export)
CREATE OR REPLACE TEMP VIEW wide_monthly_kpis AS
SELECT * FROM VALUES
  ('North',  'Warehouse A', 'Orders Shipped', 2025, 1200.0, 1300.0, 1250.0, 1400.0, 1500.0, 1450.0, 1600.0, 1550.0, 1700.0, 1650.0, 1800.0, 1750.0),
  ('North',  'Warehouse A', 'Returns',        2025,   80.0,   90.0,   85.0,   95.0,  100.0,   98.0,  105.0,  110.0,  115.0,  112.0,  120.0,  118.0),
  ('South',  'Warehouse B', 'Orders Shipped', 2025,  900.0,  950.0,  980.0, 1000.0, 1050.0, 1020.0, 1100.0, 1080.0, 1150.0, 1120.0, 1200.0, 1180.0),
  ('South',  'Warehouse B', 'Returns',        2025,   60.0,   65.0,   70.0,   72.0,   75.0,   74.0,   80.0,   82.0,   85.0,   83.0,   90.0,   88.0)
AS t(region, warehouse, metric_name, year,
     `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
     `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`);
-- Note the deliberately inconsistent column labels (trailing spaces,
-- "Sept" vs "Sep") -- this mirrors real spreadsheet exports and is exactly
-- why the normalization step below is needed.

-- COMMAND ----------

-- DBTITLE 1,Step 2: UNPIVOT + normalize inconsistent month labels into real dates
-- PATTERN: wide-to-long UNPIVOT, with a defensive CASE/lookup to normalize
-- labels that don't follow a single consistent convention.
CREATE OR REPLACE TEMP VIEW actuals_monthly_normalized AS
SELECT
  region,
  warehouse,
  metric_name,
  try_to_date(
    concat(
      CASE TRIM(month_label)
        WHEN 'Jan Val' THEN '01' WHEN 'Feb Val'  THEN '02' WHEN 'Mar Val' THEN '03'
        WHEN 'Apr Val' THEN '04' WHEN 'May Val'  THEN '05' WHEN 'Jun Val' THEN '06'
        WHEN 'Jul Val' THEN '07' WHEN 'Aug Val'  THEN '08' WHEN 'Sept Val' THEN '09'
        WHEN 'Oct Val' THEN '10' WHEN 'Nov Val'  THEN '11' WHEN 'Dec Val' THEN '12'
        ELSE NULL -- fail loudly (NULL date) rather than silently mis-parsing
                  -- an unrecognized label
      END,
      ' ', year
    ),
    'MM yyyy'
  ) AS activity_date,
  SUM(TRY_CAST(value AS DOUBLE)) AS total_value,
  'actuals_monthly_export' AS source
FROM wide_monthly_kpis
UNPIVOT (
  value FOR month_label IN (
    `Jan Val `, `Feb Val`, `Mar Val `, `Apr Val`, `May Val`, `Jun Val`,
    `Jul Val`, `Aug Val`, `Sept Val`, `Oct Val`, `Nov Val`, `Dec Val`
  )
)
GROUP BY ALL;

-- COMMAND ----------

-- DBTITLE 1,Step 3: Synthetic daily event log (a second, differently-shaped actuals source)
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
FROM actuals_monthly_normalized
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

-- DBTITLE 1,Validation: confirm no gaps or overlaps around the cutoff
SELECT
  source,
  MIN(activity_date) AS earliest,
  MAX(activity_date) AS latest,
  COUNT(*) AS row_count
FROM blended_kpi_reporting
GROUP BY source
ORDER BY earliest;
-- Expect: actuals sources end right before cutoff_date, forecast starts
-- exactly at cutoff_date, with no shared dates between them (no double count)
-- and no missing month in between.
