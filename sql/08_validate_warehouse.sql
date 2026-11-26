-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 08 - Data Warehouse Validation
-- ============================================================

-- ------------------------------------------------------------
-- 1. WAREHOUSE STRUCTURE
-- ------------------------------------------------------------

SELECT
    table_schema,
    COUNT(*) AS total_tables,
    COUNT(*) FILTER (
        WHERE table_name LIKE 'dim_%'
    ) AS dimension_tables,
    COUNT(*) FILTER (
        WHERE table_name LIKE 'fact_%'
    ) AS fact_tables
FROM information_schema.tables
WHERE table_schema IN ('staging', 'warehouse')
    AND table_type = 'BASE TABLE'
GROUP BY table_schema
ORDER BY table_schema;


-- ------------------------------------------------------------
-- 2. RECORD COUNT RECONCILIATION
-- ------------------------------------------------------------

WITH reconciliation AS (

    SELECT
        'labour_costs' AS dataset,
        (SELECT COUNT(*) FROM staging.labour_costs)
            AS staging_records,
        (SELECT COUNT(*) FROM warehouse.fact_labour_costs)
            AS warehouse_records

    UNION ALL

    SELECT
        'salary_economic_activity',
        (SELECT COUNT(*) FROM staging.salary_economic_activity),
        (SELECT COUNT(*) FROM warehouse.fact_salary_economic_activity)

    UNION ALL

    SELECT
        'salary_occupation',
        (SELECT COUNT(*) FROM staging.salary_occupation),
        (SELECT COUNT(*) FROM warehouse.fact_salary_occupation)

    UNION ALL

    SELECT
        'salary_regional_sector',
        (SELECT COUNT(*) FROM staging.salary_regional_sector),
        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_sector)

    UNION ALL

    SELECT
        'salary_regional_occupation',
        (SELECT COUNT(*) FROM staging.salary_regional_occupation),
        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_occupation)

)

SELECT
    dataset,
    staging_records,
    warehouse_records,
    staging_records - warehouse_records AS difference,

    CASE
        WHEN staging_records = warehouse_records THEN 'PASSED'
        ELSE 'FAILED'
    END AS validation_status

FROM reconciliation
ORDER BY dataset;


-- ------------------------------------------------------------
-- 3. PRIMARY AND FOREIGN KEY AUDIT
-- ------------------------------------------------------------

SELECT
    tc.table_name,

    COUNT(*) FILTER (
        WHERE tc.constraint_type = 'PRIMARY KEY'
    ) AS primary_keys,

    COUNT(*) FILTER (
        WHERE tc.constraint_type = 'FOREIGN KEY'
    ) AS foreign_keys

FROM information_schema.table_constraints tc

WHERE tc.table_schema = 'warehouse'
    AND tc.table_name LIKE 'fact_%'

GROUP BY tc.table_name
ORDER BY tc.table_name;


-- ------------------------------------------------------------
-- 4. DUPLICATE KEY VALIDATION
-- ------------------------------------------------------------

SELECT
    'fact_labour_costs' AS fact_table,
    COUNT(*) AS duplicate_keys
FROM (
    SELECT activity_id, component_id, year_id, quarter_id
    FROM warehouse.fact_labour_costs
    GROUP BY activity_id, component_id, year_id, quarter_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'fact_salary_economic_activity',
    COUNT(*)
FROM (
    SELECT activity_id, gender_id, year_id
    FROM warehouse.fact_salary_economic_activity
    GROUP BY activity_id, gender_id, year_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'fact_salary_occupation',
    COUNT(*)
FROM (
    SELECT occupation_id, gender_id, year_id
    FROM warehouse.fact_salary_occupation
    GROUP BY occupation_id, gender_id, year_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'fact_salary_regional_sector',
    COUNT(*)
FROM (
    SELECT region_id, sector_id, gender_id, year_id
    FROM warehouse.fact_salary_regional_sector
    GROUP BY region_id, sector_id, gender_id, year_id
    HAVING COUNT(*) > 1
) d

UNION ALL

SELECT
    'fact_salary_regional_occupation',
    COUNT(*)
FROM (
    SELECT region_id, occupation_id, gender_id, year_id
    FROM warehouse.fact_salary_regional_occupation
    GROUP BY region_id, occupation_id, gender_id, year_id
    HAVING COUNT(*) > 1
) d;


-- ------------------------------------------------------------
-- 5. RECORD-LEVEL RECONCILIATION
-- ------------------------------------------------------------

WITH labour_costs_check AS (

    SELECT
        COUNT(*) AS mismatches

    FROM staging.labour_costs s

    LEFT JOIN warehouse.dim_economic_activity a
        ON s.economic_activity = a.activity_name
        AND a.source_dataset = 'Labour Costs'

    LEFT JOIN warehouse.dim_cost_component c
        ON s.cost_component = c.component_name

    LEFT JOIN warehouse.dim_year y
        ON s.year = y.year

    LEFT JOIN warehouse.dim_quarter q
        ON s.quarter = q.quarter

    LEFT JOIN warehouse.fact_labour_costs f
        ON f.activity_id = a.activity_id
        AND f.component_id = c.component_id
        AND f.year_id = y.year_id
        AND f.quarter_id = q.quarter_id

    WHERE f.activity_id IS NULL
        OR s.labour_cost IS DISTINCT FROM f.labour_cost

),

economic_activity_check AS (

    SELECT COUNT(*) AS mismatches

    FROM staging.salary_economic_activity s

    LEFT JOIN warehouse.dim_economic_activity a
        ON s.economic_activity = a.activity_name
        AND a.source_dataset = 'Annual Salary'

    LEFT JOIN warehouse.dim_gender g
        ON s.gender = g.gender

    LEFT JOIN warehouse.dim_year y
        ON s.year = y.year

    LEFT JOIN warehouse.fact_salary_economic_activity f
        ON f.activity_id = a.activity_id
        AND f.gender_id = g.gender_id
        AND f.year_id = y.year_id

    WHERE f.activity_id IS NULL
        OR s.annual_salary IS DISTINCT FROM f.annual_salary
        OR s.quality_flag IS DISTINCT FROM f.quality_flag

),

occupation_check AS (

    SELECT COUNT(*) AS mismatches

    FROM staging.salary_occupation s

    LEFT JOIN warehouse.dim_national_occupation o
        ON s.occupation = o.occupation_name

    LEFT JOIN warehouse.dim_gender g
        ON s.gender = g.gender

    LEFT JOIN warehouse.dim_year y
        ON s.year = y.year

    LEFT JOIN warehouse.fact_salary_occupation f
        ON f.occupation_id = o.occupation_id
        AND f.gender_id = g.gender_id
        AND f.year_id = y.year_id

    WHERE f.occupation_id IS NULL
        OR s.annual_salary IS DISTINCT FROM f.annual_salary
        OR s.quality_flag IS DISTINCT FROM f.quality_flag

),

regional_sector_check AS (

    SELECT COUNT(*) AS mismatches

    FROM staging.salary_regional_sector s

    LEFT JOIN warehouse.dim_region r
        ON s.region = r.region_name

    LEFT JOIN warehouse.dim_sector e
        ON s.sector = e.sector_name

    LEFT JOIN warehouse.dim_gender g
        ON s.gender = g.gender

    LEFT JOIN warehouse.dim_year y
        ON s.year = y.year

    LEFT JOIN warehouse.fact_salary_regional_sector f
        ON f.region_id = r.region_id
        AND f.sector_id = e.sector_id
        AND f.gender_id = g.gender_id
        AND f.year_id = y.year_id

    WHERE f.region_id IS NULL
        OR s.annual_salary IS DISTINCT FROM f.annual_salary
        OR s.quality_flag IS DISTINCT FROM f.quality_flag

),

regional_occupation_check AS (

    SELECT COUNT(*) AS mismatches

    FROM staging.salary_regional_occupation s

    LEFT JOIN warehouse.dim_region r
        ON s.region = r.region_name

    LEFT JOIN warehouse.dim_regional_occupation o
        ON s.occupation = o.occupation_level

    LEFT JOIN warehouse.dim_gender g
        ON s.gender = g.gender

    LEFT JOIN warehouse.dim_year y
        ON s.year = y.year

    LEFT JOIN warehouse.fact_salary_regional_occupation f
        ON f.region_id = r.region_id
        AND f.occupation_id = o.occupation_id
        AND f.gender_id = g.gender_id
        AND f.year_id = y.year_id

    WHERE f.region_id IS NULL
        OR s.annual_salary IS DISTINCT FROM f.annual_salary
        OR s.quality_flag IS DISTINCT FROM f.quality_flag

),

audit_results AS (

    SELECT 'labour_costs' AS dataset, mismatches
    FROM labour_costs_check

    UNION ALL

    SELECT 'salary_economic_activity', mismatches
    FROM economic_activity_check

    UNION ALL

    SELECT 'salary_occupation', mismatches
    FROM occupation_check

    UNION ALL

    SELECT 'salary_regional_sector', mismatches
    FROM regional_sector_check

    UNION ALL

    SELECT 'salary_regional_occupation', mismatches
    FROM regional_occupation_check

)

SELECT
    dataset,
    mismatches,

    CASE
        WHEN mismatches = 0 THEN 'PASSED'
        ELSE 'FAILED'
    END AS validation_status

FROM audit_results
ORDER BY dataset;