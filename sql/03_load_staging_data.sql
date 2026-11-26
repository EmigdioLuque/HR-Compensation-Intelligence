-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 03 - Load Staging Data
-- ============================================================

\set ON_ERROR_STOP on

BEGIN;

-- ------------------------------------------------------------
-- 0. RESET STAGING TABLES
-- ------------------------------------------------------------

\echo Resetting staging tables...

TRUNCATE TABLE
    staging.labour_costs,
    staging.salary_economic_activity,
    staging.salary_occupation,
    staging.salary_regional_sector,
    staging.salary_regional_occupation;

-- ------------------------------------------------------------
-- 1. LABOUR COSTS
-- ------------------------------------------------------------

\echo Loading labour costs...

\copy staging.labour_costs (economic_activity, cost_component, period, labour_cost, year, quarter) FROM 'data/processed/labour_costs.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ------------------------------------------------------------
-- 2. SALARY BY ECONOMIC ACTIVITY
-- ------------------------------------------------------------

\echo Loading salary by economic activity...

\copy staging.salary_economic_activity (economic_activity, gender, year, annual_salary, quality_flag) FROM 'data/processed/salary_economic_activity.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ------------------------------------------------------------
-- 3. SALARY BY OCCUPATION
-- ------------------------------------------------------------

\echo Loading salary by occupation...

\copy staging.salary_occupation (occupation, gender, year, annual_salary, quality_flag) FROM 'data/processed/salary_occupation.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ------------------------------------------------------------
-- 4. REGIONAL SALARY BY SECTOR
-- ------------------------------------------------------------

\echo Loading regional salary by sector...

\copy staging.salary_regional_sector (region, sector, gender, year, annual_salary, quality_flag) FROM 'data/processed/salary_regional_sector.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ------------------------------------------------------------
-- 5. REGIONAL SALARY BY OCCUPATION
-- ------------------------------------------------------------

\echo Loading regional salary by occupation...

\copy staging.salary_regional_occupation (region, occupation, gender, year, annual_salary, quality_flag) FROM 'data/processed/salary_regional_occupation.csv' WITH (FORMAT CSV, HEADER TRUE, ENCODING 'UTF8');

-- ============================================================
-- 6. DATA LOAD VALIDATION
-- ============================================================

SELECT
    'labour_costs' AS dataset,
    COUNT(*) AS total_records
FROM staging.labour_costs

UNION ALL

SELECT
    'salary_economic_activity',
    COUNT(*)
FROM staging.salary_economic_activity

UNION ALL

SELECT
    'salary_occupation',
    COUNT(*)
FROM staging.salary_occupation

UNION ALL

SELECT
    'salary_regional_sector',
    COUNT(*)
FROM staging.salary_regional_sector

UNION ALL

SELECT
    'salary_regional_occupation',
    COUNT(*)
FROM staging.salary_regional_occupation;

-- ============================================================
-- 7. TOTAL RECORDS VALIDATION
-- ============================================================

SELECT
    (SELECT COUNT(*) FROM staging.labour_costs) +
    (SELECT COUNT(*) FROM staging.salary_economic_activity) +
    (SELECT COUNT(*) FROM staging.salary_occupation) +
    (SELECT COUNT(*) FROM staging.salary_regional_sector) +
    (SELECT COUNT(*) FROM staging.salary_regional_occupation)
    AS total_records_loaded;

-- ============================================================
-- 8. QUALITY FLAG VALIDATION
-- ============================================================

WITH salary_quality AS (

    SELECT
        'salary_economic_activity' AS dataset,
        annual_salary,
        quality_flag
    FROM staging.salary_economic_activity

    UNION ALL

    SELECT
        'salary_occupation',
        annual_salary,
        quality_flag
    FROM staging.salary_occupation

    UNION ALL

    SELECT
        'salary_regional_sector',
        annual_salary,
        quality_flag
    FROM staging.salary_regional_sector

    UNION ALL

    SELECT
        'salary_regional_occupation',
        annual_salary,
        quality_flag
    FROM staging.salary_regional_occupation

)

SELECT
    dataset,
    COUNT(*) AS total_records,
    COUNT(*) FILTER (
        WHERE quality_flag = 'STANDARD'
    ) AS standard_records,
    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    ) AS low_reliability_records,
    COUNT(*) FILTER (
        WHERE annual_salary IS NULL
    ) AS missing_values,
    COUNT(*) FILTER (
        WHERE annual_salary < 0
    ) AS negative_salaries,
    COUNT(*) FILTER (
        WHERE quality_flag IS NULL
    ) AS missing_quality_flags
FROM salary_quality
GROUP BY dataset
ORDER BY dataset;

COMMIT;

\echo Staging data successfully loaded.