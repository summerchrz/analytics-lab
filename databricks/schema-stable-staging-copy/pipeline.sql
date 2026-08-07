-- Pattern: schema-stable staging copy
--
-- Problem this solves: your pipeline reads from a table you don't own,
-- maintained by another team (a vendor feed, another department's export,
-- a legacy system dump). Reading it directly means every downstream query
-- is exposed to that table's quirks and changes: awkward column names,
-- inconsistent whitespace, permission changes, refresh timing, or a
-- structural change made by the owning team with no warning to you.
--
-- The fix: copy it into a table you own, in your own schema, before doing
-- any real transformation work against it. This single extra step buys you
-- three things:
--   1. A stable read surface — your transformation logic downstream always
--      points at *your* copy, never the upstream table directly.
--   2. The ability to clean up column names on your copy later (rename,
--      drop) via ALTER TABLE, without rewriting the underlying data files —
--      this specifically requires Delta's "column mapping" feature, off by
--      default on a plain CREATE TABLE AS SELECT.
--   3. One clear place to eventually fix known data-quality fragility
--      (see the `blended-actuals-forecast-pipeline` pattern in this repo
--      for an example of the kind of fragility this sets you up to fix).

-- 1. SYNTHETIC UPSTREAM SOURCE (stand-in for a table you don't own).
-- Note the accidental trailing space on some column names and not others —
-- extremely common in hand-maintained spreadsheet-to-table exports, and
-- exactly the kind of thing you don't want leaking into every query that
-- touches this data.
CREATE OR REPLACE TEMP VIEW external_vendor_feed AS
SELECT * FROM VALUES
  ('US',  2025, '120', '130', '140'),
  ('EMEA', 2025, '80',  '95',  '110')
AS t(region, `year`, `Jan Val `, `Feb Val`, `Mar Val `);

-- 2. STAGING COPY — this is the pattern's core step.
-- `delta.columnMapping.mode = 'name'` tells Delta to track each column by an
-- internal name-based identifier instead of its physical position in the
-- underlying Parquet files. Without it, renaming or dropping a column
-- requires rewriting every data file (expensive, and blocks concurrent
-- writers). With it, ALTER TABLE ... RENAME COLUMN / DROP COLUMN are cheap
-- metadata-only operations.
CREATE OR REPLACE TABLE staging.vendor_feed_snapshot
TBLPROPERTIES ('delta.columnMapping.mode' = 'name')
AS
SELECT *
FROM external_vendor_feed;

-- 3. WHY THIS MATTERS IN PRACTICE — cleaning up the column names is now
-- cheap and safe, instead of being a full-table rewrite:
ALTER TABLE staging.vendor_feed_snapshot RENAME COLUMN `Jan Val ` TO `jan_val`;
ALTER TABLE staging.vendor_feed_snapshot RENAME COLUMN `Feb Val`  TO `feb_val`;
ALTER TABLE staging.vendor_feed_snapshot RENAME COLUMN `Mar Val ` TO `mar_val`;

-- 4. RETIRING AN OLD NAME/LOCATION AFTER A MIGRATION.
-- If this staging table is replacing an older, differently-named copy that
-- other things might still reference, don't just drop the old one blind —
-- confirm nothing still points at it, then clean it up explicitly so you
-- don't end up with two "current" copies of the same data drifting apart.
DROP TABLE IF EXISTS staging.vendor_feed_snapshot_legacy_name;

-- 5. Everything downstream (transforms, unpivots, joins) should now read
-- from `staging.vendor_feed_snapshot` — never from `external_vendor_feed`
-- directly. That indirection is the entire point of the pattern.
SELECT * FROM staging.vendor_feed_snapshot;
