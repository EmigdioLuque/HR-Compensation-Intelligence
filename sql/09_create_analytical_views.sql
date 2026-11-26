-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 09 - Create Analytical Views
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. LABOUR COSTS ANALYTICAL VIEW
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_labour_costs AS

SELECT
    y.year,
    q.quarter,
    CONCAT(y.year, 'Q', q.quarter) AS period,
    a.activity_name AS economic_activity,
    c.component_name AS cost_component,
    f.labour_cost

FROM warehouse.fact_labour_costs f

INNER JOIN warehouse.dim_economic_activity a
    ON f.activity_id = a.activity_id

INNER JOIN warehouse.dim_cost_component c
    ON f.component_id = c.component_id

INNER JOIN warehouse.dim_year y
    ON f.year_id = y.year_id

INNER JOIN warehouse.dim_quarter q
    ON f.quarter_id = q.quarter_id;


-- ------------------------------------------------------------
-- 2. SALARY BY ECONOMIC ACTIVITY ANALYTICAL VIEW
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_salary_economic_activity AS

SELECT
    y.year,
    a.activity_name AS economic_activity,
    g.gender,
    f.annual_salary,
    f.quality_flag,

    CASE
        WHEN f.annual_salary IS NULL THEN FALSE
        WHEN f.quality_flag = 'STANDARD' THEN TRUE
        ELSE FALSE
    END AS is_reliable

FROM warehouse.fact_salary_economic_activity f

INNER JOIN warehouse.dim_economic_activity a
    ON f.activity_id = a.activity_id

INNER JOIN warehouse.dim_gender g
    ON f.gender_id = g.gender_id

INNER JOIN warehouse.dim_year y
    ON f.year_id = y.year_id;


-- ------------------------------------------------------------
-- 3. SALARY BY OCCUPATION ANALYTICAL VIEW
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_salary_occupation AS

SELECT
    y.year,
    o.occupation_name AS occupation,
    g.gender,
    f.annual_salary,
    f.quality_flag,

    CASE
        WHEN f.annual_salary IS NULL THEN FALSE
        WHEN f.quality_flag = 'STANDARD' THEN TRUE
        ELSE FALSE
    END AS is_reliable

FROM warehouse.fact_salary_occupation f

INNER JOIN warehouse.dim_national_occupation o
    ON f.occupation_id = o.occupation_id

INNER JOIN warehouse.dim_gender g
    ON f.gender_id = g.gender_id

INNER JOIN warehouse.dim_year y
    ON f.year_id = y.year_id;


-- ------------------------------------------------------------
-- 4. REGIONAL SALARY BY SECTOR ANALYTICAL VIEW
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_salary_regional_sector AS

SELECT
    y.year,
    r.region_name AS region,
    e.sector_name AS sector,
    g.gender,
    f.annual_salary,
    f.quality_flag,

    CASE
        WHEN f.annual_salary IS NULL THEN FALSE
        WHEN f.quality_flag = 'STANDARD' THEN TRUE
        ELSE FALSE
    END AS is_reliable

FROM warehouse.fact_salary_regional_sector f

INNER JOIN warehouse.dim_region r
    ON f.region_id = r.region_id

INNER JOIN warehouse.dim_sector e
    ON f.sector_id = e.sector_id

INNER JOIN warehouse.dim_gender g
    ON f.gender_id = g.gender_id

INNER JOIN warehouse.dim_year y
    ON f.year_id = y.year_id;


-- ------------------------------------------------------------
-- 5. REGIONAL SALARY BY OCCUPATION ANALYTICAL VIEW
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_salary_regional_occupation AS

SELECT
    y.year,
    r.region_name AS region,
    o.occupation_level AS occupation,
    g.gender,
    f.annual_salary,
    f.quality_flag,

    CASE
        WHEN f.annual_salary IS NULL THEN FALSE
        WHEN f.quality_flag = 'STANDARD' THEN TRUE
        ELSE FALSE
    END AS is_reliable

FROM warehouse.fact_salary_regional_occupation f

INNER JOIN warehouse.dim_region r
    ON f.region_id = r.region_id

INNER JOIN warehouse.dim_regional_occupation o
    ON f.occupation_id = o.occupation_id

INNER JOIN warehouse.dim_gender g
    ON f.gender_id = g.gender_id

INNER JOIN warehouse.dim_year y
    ON f.year_id = y.year_id;


COMMIT;


-- ============================================================
-- 6. ANALYTICAL VIEW STRUCTURE VALIDATION
-- ============================================================

SELECT
    table_schema,
    table_name,
    table_type

FROM information_schema.tables

WHERE table_schema = 'analytics'
    AND table_type = 'VIEW'

ORDER BY table_name;


-- ============================================================
-- 7. ANALYTICAL VIEW RECORD VALIDATION
-- ============================================================

WITH validation AS (

    SELECT
        'vw_labour_costs' AS analytical_view,
        (SELECT COUNT(*) FROM analytics.vw_labour_costs)
            AS view_records,
        (SELECT COUNT(*) FROM warehouse.fact_labour_costs)
            AS warehouse_records

    UNION ALL

    SELECT
        'vw_salary_economic_activity',
        (SELECT COUNT(*) FROM analytics.vw_salary_economic_activity),
        (SELECT COUNT(*) FROM warehouse.fact_salary_economic_activity)

    UNION ALL

    SELECT
        'vw_salary_occupation',
        (SELECT COUNT(*) FROM analytics.vw_salary_occupation),
        (SELECT COUNT(*) FROM warehouse.fact_salary_occupation)

    UNION ALL

    SELECT
        'vw_salary_regional_sector',
        (SELECT COUNT(*) FROM analytics.vw_salary_regional_sector),
        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_sector)

    UNION ALL

    SELECT
        'vw_salary_regional_occupation',
        (SELECT COUNT(*) FROM analytics.vw_salary_regional_occupation),
        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_occupation)

)

SELECT
    analytical_view,
    view_records,
    warehouse_records,
    view_records - warehouse_records AS difference,

    CASE
        WHEN view_records = warehouse_records THEN 'PASSED'
        ELSE 'FAILED'
    END AS validation_status

FROM validation

ORDER BY analytical_view;