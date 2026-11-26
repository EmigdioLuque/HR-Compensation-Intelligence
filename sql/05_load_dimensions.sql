-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 05 - Load Dimension Tables
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. YEAR DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_year (year)

SELECT year FROM staging.labour_costs

UNION

SELECT year FROM staging.salary_economic_activity

UNION

SELECT year FROM staging.salary_occupation

UNION

SELECT year FROM staging.salary_regional_sector

UNION

SELECT year FROM staging.salary_regional_occupation

ON CONFLICT (year) DO NOTHING;

-- ------------------------------------------------------------
-- 2. QUARTER DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_quarter (
    quarter,
    quarter_name
)

SELECT DISTINCT
    quarter,
    'Q' || quarter::TEXT
FROM staging.labour_costs

ON CONFLICT (quarter) DO NOTHING;

-- ------------------------------------------------------------
-- 3. GENDER DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_gender (
    gender,
    is_aggregate
)

VALUES
    ('All', TRUE),
    ('Male', FALSE),
    ('Female', FALSE)

ON CONFLICT (gender) DO NOTHING;

-- ------------------------------------------------------------
-- 4. REGION DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_region (
    region_name,
    is_aggregate
)

SELECT
    region,
    region = 'Total Nacional'
FROM (

    SELECT region
    FROM staging.salary_regional_sector

    UNION

    SELECT region
    FROM staging.salary_regional_occupation

) AS regions

ON CONFLICT (region_name) DO NOTHING;

-- ------------------------------------------------------------
-- 5. ECONOMIC ACTIVITY DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_economic_activity (
    activity_code,
    activity_name,
    source_dataset,
    is_aggregate
)

SELECT DISTINCT
    SPLIT_PART(economic_activity, ' ', 1),
    economic_activity,
    'Annual Salary',
    SPLIT_PART(economic_activity, ' ', 1) = 'B_S'
FROM staging.salary_economic_activity

UNION ALL

SELECT DISTINCT
    SPLIT_PART(economic_activity, ' ', 1),
    economic_activity,
    'Labour Costs',
    SPLIT_PART(economic_activity, ' ', 1) = 'B_S'
FROM staging.labour_costs

ON CONFLICT (source_dataset, activity_name) DO NOTHING;

-- ------------------------------------------------------------
-- 6. NATIONAL OCCUPATION DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_national_occupation (
    occupation_name,
    is_aggregate
)

SELECT DISTINCT
    occupation,
    occupation = 'Todas las ocupaciones'
FROM staging.salary_occupation

ON CONFLICT (occupation_name) DO NOTHING;

-- ------------------------------------------------------------
-- 7. REGIONAL OCCUPATION DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_regional_occupation (
    occupation_level,
    is_aggregate
)

SELECT DISTINCT
    occupation,
    occupation = 'Todas las ocupaciones'
FROM staging.salary_regional_occupation

ON CONFLICT (occupation_level) DO NOTHING;

-- ------------------------------------------------------------
-- 8. ECONOMIC SECTOR DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_sector (
    sector_name,
    is_aggregate
)

SELECT DISTINCT
    sector,
    sector = 'Todos los sectores'
FROM staging.salary_regional_sector

ON CONFLICT (sector_name) DO NOTHING;

-- ------------------------------------------------------------
-- 9. COST COMPONENT DIMENSION
-- ------------------------------------------------------------

INSERT INTO warehouse.dim_cost_component (
    component_name
)

SELECT DISTINCT
    cost_component
FROM staging.labour_costs

ON CONFLICT (component_name) DO NOTHING;

COMMIT;

-- ============================================================
-- 10. DIMENSION LOAD VALIDATION
-- ============================================================

SELECT
    'dim_year' AS dimension,
    COUNT(*) AS total_records
FROM warehouse.dim_year

UNION ALL

SELECT
    'dim_quarter',
    COUNT(*)
FROM warehouse.dim_quarter

UNION ALL

SELECT
    'dim_gender',
    COUNT(*)
FROM warehouse.dim_gender

UNION ALL

SELECT
    'dim_region',
    COUNT(*)
FROM warehouse.dim_region

UNION ALL

SELECT
    'dim_economic_activity',
    COUNT(*)
FROM warehouse.dim_economic_activity

UNION ALL

SELECT
    'dim_national_occupation',
    COUNT(*)
FROM warehouse.dim_national_occupation

UNION ALL

SELECT
    'dim_regional_occupation',
    COUNT(*)
FROM warehouse.dim_regional_occupation

UNION ALL

SELECT
    'dim_sector',
    COUNT(*)
FROM warehouse.dim_sector

UNION ALL

SELECT
    'dim_cost_component',
    COUNT(*)
FROM warehouse.dim_cost_component

ORDER BY dimension;