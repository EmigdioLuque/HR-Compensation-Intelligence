-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 07 - Load Fact Tables
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. LOAD LABOUR COSTS
-- ------------------------------------------------------------

INSERT INTO warehouse.fact_labour_costs (
    activity_id,
    component_id,
    year_id,
    quarter_id,
    labour_cost
)

SELECT
    a.activity_id,
    c.component_id,
    y.year_id,
    q.quarter_id,
    s.labour_cost

FROM staging.labour_costs s

INNER JOIN warehouse.dim_economic_activity a
    ON s.economic_activity = a.activity_name
    AND a.source_dataset = 'Labour Costs'

INNER JOIN warehouse.dim_cost_component c
    ON s.cost_component = c.component_name

INNER JOIN warehouse.dim_year y
    ON s.year = y.year

INNER JOIN warehouse.dim_quarter q
    ON s.quarter = q.quarter

ON CONFLICT (
    activity_id,
    component_id,
    year_id,
    quarter_id
)
DO UPDATE SET
    labour_cost = EXCLUDED.labour_cost;


-- ------------------------------------------------------------
-- 2. LOAD SALARY BY ECONOMIC ACTIVITY
-- ------------------------------------------------------------

INSERT INTO warehouse.fact_salary_economic_activity (
    activity_id,
    gender_id,
    year_id,
    annual_salary,
    quality_flag
)

SELECT
    a.activity_id,
    g.gender_id,
    y.year_id,
    s.annual_salary,
    s.quality_flag

FROM staging.salary_economic_activity s

INNER JOIN warehouse.dim_economic_activity a
    ON s.economic_activity = a.activity_name
    AND a.source_dataset = 'Annual Salary'

INNER JOIN warehouse.dim_gender g
    ON s.gender = g.gender

INNER JOIN warehouse.dim_year y
    ON s.year = y.year

ON CONFLICT (
    activity_id,
    gender_id,
    year_id
)
DO UPDATE SET
    annual_salary = EXCLUDED.annual_salary,
    quality_flag = EXCLUDED.quality_flag;


-- ------------------------------------------------------------
-- 3. LOAD SALARY BY OCCUPATION
-- ------------------------------------------------------------

INSERT INTO warehouse.fact_salary_occupation (
    occupation_id,
    gender_id,
    year_id,
    annual_salary,
    quality_flag
)

SELECT
    o.occupation_id,
    g.gender_id,
    y.year_id,
    s.annual_salary,
    s.quality_flag

FROM staging.salary_occupation s

INNER JOIN warehouse.dim_national_occupation o
    ON s.occupation = o.occupation_name

INNER JOIN warehouse.dim_gender g
    ON s.gender = g.gender

INNER JOIN warehouse.dim_year y
    ON s.year = y.year

ON CONFLICT (
    occupation_id,
    gender_id,
    year_id
)
DO UPDATE SET
    annual_salary = EXCLUDED.annual_salary,
    quality_flag = EXCLUDED.quality_flag;


-- ------------------------------------------------------------
-- 4. LOAD REGIONAL SALARY BY SECTOR
-- ------------------------------------------------------------

INSERT INTO warehouse.fact_salary_regional_sector (
    region_id,
    sector_id,
    gender_id,
    year_id,
    annual_salary,
    quality_flag
)

SELECT
    r.region_id,
    e.sector_id,
    g.gender_id,
    y.year_id,
    s.annual_salary,
    s.quality_flag

FROM staging.salary_regional_sector s

INNER JOIN warehouse.dim_region r
    ON s.region = r.region_name

INNER JOIN warehouse.dim_sector e
    ON s.sector = e.sector_name

INNER JOIN warehouse.dim_gender g
    ON s.gender = g.gender

INNER JOIN warehouse.dim_year y
    ON s.year = y.year

ON CONFLICT (
    region_id,
    sector_id,
    gender_id,
    year_id
)
DO UPDATE SET
    annual_salary = EXCLUDED.annual_salary,
    quality_flag = EXCLUDED.quality_flag;


-- ------------------------------------------------------------
-- 5. LOAD REGIONAL SALARY BY OCCUPATION
-- ------------------------------------------------------------

INSERT INTO warehouse.fact_salary_regional_occupation (
    region_id,
    occupation_id,
    gender_id,
    year_id,
    annual_salary,
    quality_flag
)

SELECT
    r.region_id,
    o.occupation_id,
    g.gender_id,
    y.year_id,
    s.annual_salary,
    s.quality_flag

FROM staging.salary_regional_occupation s

INNER JOIN warehouse.dim_region r
    ON s.region = r.region_name

INNER JOIN warehouse.dim_regional_occupation o
    ON s.occupation = o.occupation_level

INNER JOIN warehouse.dim_gender g
    ON s.gender = g.gender

INNER JOIN warehouse.dim_year y
    ON s.year = y.year

ON CONFLICT (
    region_id,
    occupation_id,
    gender_id,
    year_id
)
DO UPDATE SET
    annual_salary = EXCLUDED.annual_salary,
    quality_flag = EXCLUDED.quality_flag;


-- ============================================================
-- 6. VALIDATE RECORD COUNTS BEFORE COMMIT
-- ============================================================

DO $$
BEGIN

    IF
        (SELECT COUNT(*) FROM warehouse.fact_labour_costs)
        <>
        (SELECT COUNT(*) FROM staging.labour_costs)

        OR

        (SELECT COUNT(*) FROM warehouse.fact_salary_economic_activity)
        <>
        (SELECT COUNT(*) FROM staging.salary_economic_activity)

        OR

        (SELECT COUNT(*) FROM warehouse.fact_salary_occupation)
        <>
        (SELECT COUNT(*) FROM staging.salary_occupation)

        OR

        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_sector)
        <>
        (SELECT COUNT(*) FROM staging.salary_regional_sector)

        OR

        (SELECT COUNT(*) FROM warehouse.fact_salary_regional_occupation)
        <>
        (SELECT COUNT(*) FROM staging.salary_regional_occupation)

    THEN

        RAISE EXCEPTION
            'Data validation failed: record count mismatch';

    END IF;

    RAISE NOTICE
        'All fact table record counts validated successfully';

END $$;


-- ============================================================
-- 7. VALIDATE SALARY DATA QUALITY
-- ============================================================

DO $$

DECLARE

    table_suffix TEXT;
    staging_table TEXT;
    fact_table TEXT;

    staging_quality JSONB;
    warehouse_quality JSONB;

    invalid_records BIGINT;

BEGIN

    FOREACH table_suffix IN ARRAY ARRAY[
        'salary_economic_activity',
        'salary_occupation',
        'salary_regional_sector',
        'salary_regional_occupation'
    ]

    LOOP

        staging_table := table_suffix;
        fact_table := 'fact_' || table_suffix;

        -- Compare staging and warehouse quality indicators

        EXECUTE format(
            'SELECT jsonb_build_object(
                ''records'', COUNT(*),
                ''missing'', COUNT(*) FILTER (
                    WHERE annual_salary IS NULL
                ),
                ''standard'', COUNT(*) FILTER (
                    WHERE quality_flag = ''STANDARD''
                ),
                ''low_reliability'', COUNT(*) FILTER (
                    WHERE quality_flag = ''LOW_RELIABILITY''
                )
            )
            FROM staging.%I',
            staging_table
        )
        INTO staging_quality;

        EXECUTE format(
            'SELECT jsonb_build_object(
                ''records'', COUNT(*),
                ''missing'', COUNT(*) FILTER (
                    WHERE annual_salary IS NULL
                ),
                ''standard'', COUNT(*) FILTER (
                    WHERE quality_flag = ''STANDARD''
                ),
                ''low_reliability'', COUNT(*) FILTER (
                    WHERE quality_flag = ''LOW_RELIABILITY''
                )
            )
            FROM warehouse.%I',
            fact_table
        )
        INTO warehouse_quality;

        IF staging_quality IS DISTINCT FROM warehouse_quality THEN

            RAISE EXCEPTION
                'Quality indicators mismatch in %',
                fact_table;

        END IF;

        -- Validate monetary values and quality flags

        EXECUTE format(
            'SELECT COUNT(*)
            FROM warehouse.%I
            WHERE annual_salary < 0
                OR quality_flag IS NULL
                OR (
                    annual_salary IS NOT NULL
                    AND quality_flag NOT IN (
                        ''STANDARD'',
                        ''LOW_RELIABILITY''
                    )
                )
                OR (
                    annual_salary IS NULL
                    AND quality_flag IN (
                        ''STANDARD'',
                        ''LOW_RELIABILITY''
                    )
                )',
            fact_table
        )
        INTO invalid_records;

        IF invalid_records > 0 THEN

            RAISE EXCEPTION
                'Invalid salary records detected in %: %',
                fact_table,
                invalid_records;

        END IF;

        RAISE NOTICE
            'Data quality validated successfully: %',
            fact_table;

    END LOOP;

    -- Validate missing labour cost values

    IF
        (
            SELECT COUNT(*) - COUNT(labour_cost)
            FROM warehouse.fact_labour_costs
        )
        <>
        (
            SELECT COUNT(*) - COUNT(labour_cost)
            FROM staging.labour_costs
        )

    THEN

        RAISE EXCEPTION
            'Missing labour cost values mismatch';

    END IF;

    RAISE NOTICE
        'All data quality validations passed';

END $$;


COMMIT;


-- ============================================================
-- 8. FACT TABLE LOAD SUMMARY
-- ============================================================

SELECT
    'fact_labour_costs' AS fact_table,
    COUNT(*) AS total_records,
    COUNT(*) - COUNT(labour_cost) AS missing_values,
    NULL::BIGINT AS low_reliability_records

FROM warehouse.fact_labour_costs

UNION ALL

SELECT
    'fact_salary_economic_activity',
    COUNT(*),
    COUNT(*) - COUNT(annual_salary),
    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    )

FROM warehouse.fact_salary_economic_activity

UNION ALL

SELECT
    'fact_salary_occupation',
    COUNT(*),
    COUNT(*) - COUNT(annual_salary),
    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    )

FROM warehouse.fact_salary_occupation

UNION ALL

SELECT
    'fact_salary_regional_sector',
    COUNT(*),
    COUNT(*) - COUNT(annual_salary),
    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    )

FROM warehouse.fact_salary_regional_sector

UNION ALL

SELECT
    'fact_salary_regional_occupation',
    COUNT(*),
    COUNT(*) - COUNT(annual_salary),
    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    )

FROM warehouse.fact_salary_regional_occupation

ORDER BY fact_table;


-- ============================================================
-- 9. GLOBAL WAREHOUSE VALIDATION
-- ============================================================

WITH warehouse_data AS (

    SELECT
        labour_cost AS monetary_value,
        NULL::TEXT AS quality_flag
    FROM warehouse.fact_labour_costs

    UNION ALL

    SELECT annual_salary, quality_flag
    FROM warehouse.fact_salary_economic_activity

    UNION ALL

    SELECT annual_salary, quality_flag
    FROM warehouse.fact_salary_occupation

    UNION ALL

    SELECT annual_salary, quality_flag
    FROM warehouse.fact_salary_regional_sector

    UNION ALL

    SELECT annual_salary, quality_flag
    FROM warehouse.fact_salary_regional_occupation

)

SELECT
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE monetary_value IS NULL
    ) AS total_missing_values,

    COUNT(*) FILTER (
        WHERE quality_flag = 'LOW_RELIABILITY'
    ) AS total_low_reliability,

    'LOAD COMPLETED' AS load_status

FROM warehouse_data;