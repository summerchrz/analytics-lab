-- Report-period dim + fail-loud gate (synthetic, standalone)
-- Swap the widget value between 2026Q2 (pass) and 2026Q3 (fail: no SEP2026 upstream)

CREATE OR REPLACE TEMP VIEW dim_reporting_period AS
SELECT * FROM VALUES
  ('2026Q1', 'QUARTERLY', '2026Q1', 'MAR2026', 2026, 1),
  ('2026Q2', 'QUARTERLY', '2026Q2', 'JUN2026', 2026, 2),
  ('2026Q3', 'QUARTERLY', '2026Q3', 'SEP2026', 2026, 3)
AS d(report_period, period_kind, period_label, operating_month, calendar_year, quarter_num);

-- Fake upstream month-end fact: closed through JUN only
CREATE OR REPLACE TEMP VIEW upstream_month_end AS
SELECT * FROM VALUES
  ('MAR2026', 'NORTH', 100),
  ('JUN2026', 'NORTH', 110),
  ('JUN2026', 'SOUTH', 95)
AS u(operating_month, region, units);

-- === Widget / job param (edit this one line to simulate) ===
CREATE OR REPLACE TEMP VIEW run_params AS
SELECT '2026Q2' AS report_period;
-- SELECT '2026Q3' AS report_period;  -- expect operating_month_exists = false

CREATE OR REPLACE TEMP VIEW resolved AS
SELECT
  p.report_period,
  d.operating_month,
  d.period_label
FROM run_params p
LEFT JOIN dim_reporting_period d
  ON d.report_period = p.report_period
 AND d.period_kind = 'QUARTERLY';

-- Gate results (consume in Python/notebook: raise if any passed = false)
SELECT check_name, passed, detail FROM (
  SELECT
    'report_period_mapped' AS check_name,
    COUNT(*) = 1 AS passed,
    CAST(MAX(report_period) AS STRING) AS detail
  FROM resolved
  WHERE operating_month IS NOT NULL

  UNION ALL

  SELECT
    'operating_month_exists',
    COUNT(*) > 0,
    MAX(r.operating_month)
  FROM resolved r
  JOIN upstream_month_end u
    ON u.operating_month = r.operating_month

  UNION ALL

  SELECT
    'upstream_has_multiple_regions',
    COUNT(DISTINCT u.region) >= 2,
    CAST(COUNT(DISTINCT u.region) AS STRING)
  FROM resolved r
  JOIN upstream_month_end u
    ON u.operating_month = r.operating_month
);
