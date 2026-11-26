-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 14 - Gender Pay Gap Analytics
-- ============================================================

BEGIN;

CREATE OR REPLACE VIEW analytics.vw_gender_pay_gap AS

-- ============================================================
-- 1. CONSOLIDATE SALARY DATA
-- ============================================================

WITH salary_data AS (

    -- National and economic activity

    SELECT
        CASE
            WHEN economic_activity = 'B_S Todas las secciones'
                THEN 'National'
            ELSE 'Economic Activity'
        END AS analysis_type,

        economic_activity AS category,
        'Total Nacional'::TEXT AS region,
        year,
        gender,
        annual_salary,
        quality_flag

    FROM analytics.vw_salary_economic_activity

    UNION ALL

    -- National occupational groups

    SELECT
        'Occupation',
        occupation,
        'Total Nacional',
        year,
        gender,
        annual_salary,
        quality_flag

    FROM analytics.vw_salary_occupation

    WHERE occupation <> 'Todas las ocupaciones'

    UNION ALL

    -- Regional and sector analysis

    SELECT
        CASE
            WHEN sector LIKE 'Todos%'
                THEN 'Regional'
            ELSE 'Regional Sector'
        END,

        sector,
        region,
        year,
        gender,
        annual_salary,
        quality_flag

    FROM analytics.vw_salary_regional_sector

    WHERE region <> 'Total Nacional'

    UNION ALL

    -- Regional occupational analysis

    SELECT
        'Regional Occupation',
        occupation,
        region,
        year,
        gender,
        annual_salary,
        quality_flag

    FROM analytics.vw_salary_regional_occupation

    WHERE region <> 'Total Nacional'
        AND occupation NOT LIKE 'Todas%'

),

-- ============================================================
-- 2. SALARY AGGREGATION BY GENDER
-- ============================================================

gender_salaries AS (

    SELECT
        analysis_type,
        category,
        region,
        year,

        MAX(annual_salary) FILTER (
            WHERE gender = 'All'
        ) AS average_salary,

        MAX(annual_salary) FILTER (
            WHERE gender = 'Male'
        ) AS male_salary,

        MAX(annual_salary) FILTER (
            WHERE gender = 'Female'
        ) AS female_salary,

        MAX(quality_flag) FILTER (
            WHERE gender = 'Male'
        ) AS male_quality_flag,

        MAX(quality_flag) FILTER (
            WHERE gender = 'Female'
        ) AS female_quality_flag

    FROM salary_data

    GROUP BY
        analysis_type,
        category,
        region,
        year

),

-- ============================================================
-- 3. GENDER PAY GAP CALCULATIONS
-- ============================================================

pay_gap_metrics AS (

    SELECT
        *,

        ROUND(
            male_salary - female_salary,
            2
        ) AS salary_gap_eur,

        ROUND(
            100.0 * (male_salary - female_salary)
            / NULLIF(male_salary, 0),
            2
        ) AS gender_pay_gap_pct,

        ROUND(
            100.0 * female_salary
            / NULLIF(male_salary, 0),
            2
        ) AS female_to_male_salary_ratio,

        CASE

            WHEN male_salary IS NULL
                OR female_salary IS NULL
                THEN 'MISSING'

            WHEN male_salary <= 0
                OR female_salary <= 0
                THEN 'INVALID'

            WHEN male_quality_flag = 'LOW_RELIABILITY'
                OR female_quality_flag = 'LOW_RELIABILITY'
                THEN 'LOW_RELIABILITY'

            WHEN male_quality_flag IS NULL
                OR female_quality_flag IS NULL
                THEN 'UNKNOWN'

            WHEN male_quality_flag = 'STANDARD'
                AND female_quality_flag = 'STANDARD'
                THEN 'STANDARD'

            ELSE 'UNKNOWN'

        END AS gap_quality_flag

    FROM gender_salaries

),

-- ============================================================
-- 4. HISTORICAL EVOLUTION
-- ============================================================

historical_metrics AS (

    SELECT
        *,

        LAG(year) OVER (
            PARTITION BY analysis_type, category, region
            ORDER BY year
        ) AS previous_year,

        LAG(gender_pay_gap_pct) OVER (
            PARTITION BY analysis_type, category, region
            ORDER BY year
        ) AS previous_year_gap_pct,

        LAG(gap_quality_flag) OVER (
            PARTITION BY analysis_type, category, region
            ORDER BY year
        ) AS previous_year_quality_flag

    FROM pay_gap_metrics

),

-- ============================================================
-- 5. ANNUAL CHANGE
-- ============================================================

annual_changes AS (

    SELECT
        *,

        CASE
            WHEN previous_year = year - 1
                AND gap_quality_flag = 'STANDARD'
                AND previous_year_quality_flag = 'STANDARD'

            THEN ROUND(
                gender_pay_gap_pct - previous_year_gap_pct,
                2
            )

            ELSE NULL

        END AS gap_change_yoy_pp

    FROM historical_metrics

)

-- ============================================================
-- 6. FINAL ANALYTICAL VIEW
-- ============================================================

SELECT
    analysis_type,
    category,
    region,
    year,
    average_salary,
    male_salary,
    female_salary,
    salary_gap_eur,
    gender_pay_gap_pct,
    female_to_male_salary_ratio,
    previous_year_gap_pct,
    gap_change_yoy_pp,

    CASE

        WHEN gap_quality_flag = 'MISSING'
            THEN 'Insufficient Data'

        WHEN gap_quality_flag = 'INVALID'
            THEN 'Invalid Data'

        WHEN gap_quality_flag = 'LOW_RELIABILITY'
            THEN 'Low Reliability'

        WHEN gap_quality_flag = 'UNKNOWN'
            THEN 'Unknown Reliability'

        WHEN gender_pay_gap_pct > 0
            THEN 'Male Salary Higher'

        WHEN gender_pay_gap_pct < 0
            THEN 'Female Salary Higher'

        WHEN gender_pay_gap_pct = 0
            THEN 'Salary Parity'

        ELSE 'Insufficient Data'

    END AS gap_direction,

    CASE

        WHEN gap_change_yoy_pp IS NULL
            THEN 'Not Comparable'

        WHEN gap_change_yoy_pp < 0
            THEN 'Decreasing'

        WHEN gap_change_yoy_pp > 0
            THEN 'Increasing'

        ELSE 'Stable'

    END AS gap_trend,

    male_quality_flag,
    female_quality_flag,
    gap_quality_flag

FROM annual_changes;

COMMIT;


-- ============================================================
-- 7. ANALYSIS COVERAGE VALIDATION
-- ============================================================

SELECT
    analysis_type,
    COUNT(*) AS total_records,

    COUNT(*) FILTER (
        WHERE gap_quality_flag = 'STANDARD'
    ) AS standard_records,

    COUNT(*) FILTER (
        WHERE gap_quality_flag = 'LOW_RELIABILITY'
    ) AS low_reliability_records,

    COUNT(*) FILTER (
        WHERE gap_quality_flag = 'MISSING'
    ) AS missing_records,

    COUNT(*) FILTER (
        WHERE gap_quality_flag IN ('INVALID', 'UNKNOWN')
    ) AS other_quality_issues,

    MIN(year) AS first_year,
    MAX(year) AS latest_year

FROM analytics.vw_gender_pay_gap

GROUP BY analysis_type

ORDER BY analysis_type;


-- ============================================================
-- 8. NATIONAL GENDER PAY GAP
-- ============================================================

SELECT
    year,
    male_salary,
    female_salary,
    salary_gap_eur,
    gender_pay_gap_pct,
    female_to_male_salary_ratio,
    gap_change_yoy_pp,
    gap_trend,
    gap_quality_flag

FROM analytics.vw_gender_pay_gap

WHERE analysis_type = 'National'

ORDER BY year DESC;


-- ============================================================
-- 9. LATEST NATIONAL GENDER PAY GAP
-- ============================================================

SELECT
    year,
    male_salary,
    female_salary,
    salary_gap_eur,
    gender_pay_gap_pct,
    female_to_male_salary_ratio,
    gap_change_yoy_pp,
    gap_direction,
    gap_trend,
    gap_quality_flag

FROM analytics.vw_gender_pay_gap

WHERE analysis_type = 'National'

ORDER BY year DESC

LIMIT 1;