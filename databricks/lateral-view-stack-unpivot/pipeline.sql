-- Databricks notebook source
-- ============================================================================
-- PATTERN: Unpivoting a handful of named measures with LATERAL VIEW STACK
-- ============================================================================
-- Different tool from UNPIVOT (see ../blended-actuals-forecast-pipeline),
-- and worth knowing which to reach for:
--
--   UNPIVOT              -> you have a TABLE/VIEW with wide columns and want
--                            to turn column names into row values directly.
--   LATERAL VIEW STACK    -> you're already inside a SELECT (often after
--                            aggregating several differently-named measures
--                            into one row per key) and want to explode a
--                            handful of *computed* columns into rows,
--                            without needing a separate UNPIVOT on a
--                            materialized wide table.
--
-- STACK is especially useful when the "columns to unpivot" are the result of
-- aggregation (SUM(...) AS adds, SUM(...) AS returns, ...) rather than
-- pre-existing wide columns in a source table.
-- ============================================================================

-- COMMAND ----------

-- DBTITLE 1,Step 1: Synthetic daily transaction log (source is a normal long/event table)
CREATE OR REPLACE TEMP VIEW warehouse_daily_events AS
SELECT * FROM VALUES
  ('Warehouse A', DATE'2025-11-01', 12, 3, 1),
  ('Warehouse A', DATE'2025-11-02',  8, 1, 0),
  ('Warehouse B', DATE'2025-11-01', 20, 4, 2),
  ('Warehouse B', DATE'2025-11-02', 15, 2, 1)
AS t(warehouse, event_date, units_received, units_returned, units_damaged);

-- COMMAND ----------

-- DBTITLE 1,Step 2: Roll up to one row per key (still wide -- 3 measure columns)
CREATE OR REPLACE TEMP VIEW warehouse_daily_rolled AS
SELECT
  warehouse,
  event_date,
  SUM(units_received) AS received,
  SUM(units_returned) AS returned,
  SUM(units_damaged)  AS damaged
FROM warehouse_daily_events
GROUP BY warehouse, event_date;

-- COMMAND ----------

-- DBTITLE 1,Step 3: LATERAL VIEW STACK - explode the 3 measure columns into rows
-- The "3" in STACK(3, ...) is the number of (label, value) pairs that
-- follow. Get this wrong (e.g. add a 4th metric but leave it as STACK(3,...))
-- and Spark will either error or silently misalign labels/values -- always
-- update the count when adding or removing a metric.
CREATE OR REPLACE TEMP VIEW warehouse_metrics_long AS
SELECT
  warehouse,
  event_date AS activity_date,
  metric_name,
  metric_value,
  'warehouse_daily_rolled' AS source
FROM warehouse_daily_rolled
LATERAL VIEW STACK(
  3,
  'Units Received', received,
  'Units Returned', returned,
  'Units Damaged',  damaged
) s AS metric_name, metric_value;

-- COMMAND ----------

-- DBTITLE 1,Validation: row count should be exactly 3x the rolled-up row count
SELECT
  (SELECT COUNT(*) FROM warehouse_daily_rolled) * 3 AS expected_rows,
  (SELECT COUNT(*) FROM warehouse_metrics_long)     AS actual_rows;
-- If these don't match, the STACK count and the number of label/value pairs
-- are out of sync -- fix the mismatch before trusting downstream output.
