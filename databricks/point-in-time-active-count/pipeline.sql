-- Databricks notebook source
-- ============================================================================
-- PATTERN: Point-in-time "active as of" count from a periodic snapshot table
-- ============================================================================
-- Common in fleet/inventory/subscription reporting: a source table already
-- contains one row per (item, snapshot_date) representing that item's status
-- ON that date. To count how many items were "active" as of any given
-- snapshot date, compare each item's add_date to the snapshot_date.
--
-- IMPORTANT ASSUMPTION (call this out explicitly, don't bury it in code):
-- this pattern is only correct if the source is a genuine periodic SNAPSHOT
-- (i.e. an item that left inventory simply stops appearing in later
-- snapshots). If the source were an EVENT LOG instead (adds and removals as
-- separate rows, with items persisting after removal), this same formula
-- would over-count, and you'd need an additional
-- "removed_date IS NULL OR removed_date > snapshot_date" condition. Always
-- confirm which shape your source actually is before reusing this.
-- ============================================================================

-- COMMAND ----------

-- DBTITLE 1,Step 1: Synthetic daily snapshot table (one row per item per day it was in inventory)
-- In a true snapshot table, an item simply has no row on/after the day it
-- left inventory -- there's no explicit "removed" flag to check.
CREATE OR REPLACE TEMP VIEW inventory_snapshot_daily AS
SELECT * FROM VALUES
  ('ITEM-001', DATE'2025-11-01', DATE'2025-10-15', 'Owned'),
  ('ITEM-001', DATE'2025-11-02', DATE'2025-10-15', 'Owned'),
  ('ITEM-002', DATE'2025-11-01', DATE'2025-11-01', 'Leased'),
  ('ITEM-002', DATE'2025-11-02', DATE'2025-11-01', 'Leased'),
  ('ITEM-003', DATE'2025-11-01', DATE'2025-09-01', 'Owned')
  -- ITEM-003 has no row on 2025-11-02 -- it left inventory between the two
  -- snapshots (this is how "removal" shows up in a snapshot table: absence,
  -- not a flag).
AS t(item_id, snapshot_date, add_date, ownership_type);

-- COMMAND ----------

-- DBTITLE 1,Step 2: Classify + count active items as of each snapshot date
-- PATTERN: SUM(CASE WHEN add_date < snapshot_date THEN 1 ELSE 0 END) counts
-- items that had already been added as of that snapshot. Because absence
-- from the snapshot already handles "removed" items, no separate removal
-- condition is needed here -- see the assumption note above.
CREATE OR REPLACE TABLE active_inventory_by_type AS
SELECT
  snapshot_date,
  CASE
    WHEN ownership_type IN ('Leased', 'Leased - Short Term') THEN 'LEASED'
    ELSE 'OWNED'
  END AS ownership_group,
  SUM(CASE WHEN add_date < snapshot_date THEN 1 ELSE 0 END) AS active_count
FROM inventory_snapshot_daily
GROUP BY
  snapshot_date,
  CASE
    WHEN ownership_type IN ('Leased', 'Leased - Short Term') THEN 'LEASED'
    ELSE 'OWNED'
  END;

-- COMMAND ----------

-- DBTITLE 1,Validation: confirm the count drops when an item leaves the snapshot
SELECT * FROM active_inventory_by_type ORDER BY snapshot_date, ownership_group;
-- Expect: OWNED count on 2025-11-01 = 2 (ITEM-001 added 10-15, ITEM-003 added
-- 09-01; both < 11-01). OWNED count on 2025-11-02 = 1 (ITEM-003 no longer
-- appears in the snapshot at all, so it's excluded automatically -- this is
-- the mechanism, not a bug to fix).
