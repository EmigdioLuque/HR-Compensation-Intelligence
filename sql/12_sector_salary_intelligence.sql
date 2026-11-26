-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 12 - Sector Salary Intelligence
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_sector_salary_intelligence AS

-- ------------------------------------------------------------
-- 1. BASE SALARY DATA
-- ------------------------------------------------------------

WITH base_data AS (

    SELECT
        economic_activity,
        gender,
        year,
        annual_salary

    FROM analytics.vw_salary_economic_activity

    WHERE quality_flag = 'STANDARD'
        AND annual_salary IS NOT NULL

),

-- ------------------------------------------------------------
-- 2. NATIONAL SALARY BENCHMARK
-- ------------------------------------------------------------

national_benchmark AS (

    SELECT
        year,
        annual_salary AS national_salary

    FROM base_data

    WHERE economic_activity = 'B_S Todas las secciones'
        AND gender = 'All'

),

-- ------------------------------------------------------------
-- 3. SALARY BY ECONOMIC ACTIVITY
-- ------------------------------------------------------------

sector_data AS (

    SELECT
        economic_activity,
        year,

        MAX(annual_salary) FILTER (
            WHERE gender = 'All'
        ) AS average_salary,

        MAX(annual_salary) FILTER (
            WHERE gender = 'Male'
        ) AS male_salary,

        MAX(annual_salary) FILTER (
            WHERE gender = 'Female'
        ) AS female_salary

    FROM base_data

    WHERE economic_activity <> 'B_S Todas las secciones'

    GROUP BY
        economic_activity,
        year

),

-- ------------------------------------------------------------
-- 4. HISTORICAL SALARY EVOLUTION
-- ------------------------------------------------------------

sector_history AS (

    SELECT
        *,

        LAG(average_salary) OVER (
            PARTITION BY economic_activity
            ORDER BY year
        ) AS previous_year_salary,

        LAG(year) OVER (
            PARTITION BY economic_activity
            ORDER BY year
        ) AS previous_year

    FROM sector_data

),

-- ------------------------------------------------------------
-- 5. SECTOR SALARY METRICS
-- ------------------------------------------------------------

sector_metrics AS (

    SELECT
        s.economic_activity,
        s.year,
        s.average_salary,
        s.male_salary,
        s.female_salary,
        n.national_salary,
        s.previous_year_salary,

        -- Salary difference against national average

        ROUND(
            s.average_salary - n.national_salary,
            2
        ) AS salary_difference_eur,

        ROUND(
            100.0 *
            (s.average_salary - n.national_salary)
            / NULLIF(n.national_salary, 0),
            2
        ) AS salary_difference_pct,

        -- Salary competitiveness index

        ROUND(
            100.0 * s.average_salary
            / NULLIF(n.national_salary, 0),
            2
        ) AS sector_salary_index,

        -- Annual salary growth

        CASE
            WHEN s.previous_year = s.year - 1
            THEN ROUND(
                100.0 *
                (s.average_salary - s.previous_year_salary)
                / NULLIF(s.previous_year_salary, 0),
                2
            )
        END AS salary_growth_yoy_pct,

        -- Gender pay gap in euros

        ROUND(
            s.male_salary - s.female_salary,
            2
        ) AS gender_pay_gap_eur,

        -- Unadjusted gender pay gap percentage

        ROUND(
            100.0 *
            (s.male_salary - s.female_salary)
            / NULLIF(s.male_salary, 0),
            2
        ) AS gender_pay_gap_pct

    FROM sector_history s

    INNER JOIN national_benchmark n
        ON s.year = n.year

    WHERE s.average_salary IS NOT NULL

)

-- ------------------------------------------------------------
-- 6. SECTOR RANKING AND CLASSIFICATION
-- ------------------------------------------------------------

SELECT
    *,

    DENSE_RANK() OVER (
        PARTITION BY year
        ORDER BY average_salary DESC
    ) AS sector_salary_rank,

    CASE

        WHEN average_salary > national_salary
            THEN 'Above National Average'

        WHEN average_salary < national_salary
            THEN 'Below National Average'

        ELSE 'Equal to National Average'

    END AS benchmark_position

FROM sector_metrics;


-- ============================================================
-- 7. HISTORICAL SECTOR ANALYSIS
-- ============================================================

SELECT *
FROM analytics.vw_sector_salary_intelligence
ORDER BY year DESC, sector_salary_rank;


-- ============================================================
-- 8. LATEST AVAILABLE YEAR RANKING
-- ============================================================

SELECT
    year,
    sector_salary_rank,
    economic_activity,
    average_salary,
    national_salary,
    salary_difference_pct,
    sector_salary_index,
    salary_growth_yoy_pct,
    gender_pay_gap_pct,
    benchmark_position

FROM analytics.vw_sector_salary_intelligence

WHERE year = (

    SELECT MAX(year)
    FROM analytics.vw_sector_salary_intelligence

)

ORDER BY sector_salary_rank;