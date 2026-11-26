-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 11 - Regional Salary Benchmarking
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_regional_benchmarking AS

WITH base_data AS (

    SELECT
        region,
        year,
        annual_salary

    FROM analytics.vw_salary_regional_sector

    WHERE sector LIKE 'Todos%'
        AND gender = 'All'
        AND quality_flag = 'STANDARD'
        AND annual_salary IS NOT NULL

),

-- ------------------------------------------------------------
-- 1. NATIONAL SALARY BENCHMARK
-- ------------------------------------------------------------

national_benchmark AS (

    SELECT
        year,
        annual_salary AS national_salary

    FROM base_data

    WHERE region = 'Total Nacional'

),

-- ------------------------------------------------------------
-- 2. REGIONAL SALARY DATA
-- ------------------------------------------------------------

regional_data AS (

    SELECT
        region,
        year,
        annual_salary AS regional_salary

    FROM base_data

    WHERE region <> 'Total Nacional'

),

-- ------------------------------------------------------------
-- 3. HISTORICAL SALARY EVOLUTION
-- ------------------------------------------------------------

regional_history AS (

    SELECT
        region,
        year,
        regional_salary,

        LAG(regional_salary) OVER (
            PARTITION BY region
            ORDER BY year
        ) AS previous_year_salary,

        LAG(year) OVER (
            PARTITION BY region
            ORDER BY year
        ) AS previous_year

    FROM regional_data

),

-- ------------------------------------------------------------
-- 4. REGIONAL BENCHMARKING METRICS
-- ------------------------------------------------------------

benchmarking AS (

    SELECT
        r.region,
        r.year,
        r.regional_salary,
        n.national_salary,
        r.previous_year_salary,

        ROUND(
            r.regional_salary - n.national_salary,
            2
        ) AS salary_difference_eur,

        ROUND(
            100.0 *
            (r.regional_salary - n.national_salary)
            / NULLIF(n.national_salary, 0),
            2
        ) AS salary_difference_pct,

        ROUND(
            100.0 * r.regional_salary
            / NULLIF(n.national_salary, 0),
            2
        ) AS regional_salary_index,

        CASE
            WHEN r.previous_year = r.year - 1
            THEN ROUND(
                100.0 *
                (r.regional_salary - r.previous_year_salary)
                / NULLIF(r.previous_year_salary, 0),
                2
            )
        END AS salary_growth_yoy_pct,

        DENSE_RANK() OVER (
            PARTITION BY r.year
            ORDER BY r.regional_salary DESC
        ) AS regional_salary_rank,

        CASE
            WHEN r.regional_salary > n.national_salary
                THEN 'Above National Average'

            WHEN r.regional_salary < n.national_salary
                THEN 'Below National Average'

            ELSE 'Equal to National Average'

        END AS benchmark_position

    FROM regional_history r

    INNER JOIN national_benchmark n
        ON r.year = n.year

)

SELECT *
FROM benchmarking;


-- ============================================================
-- 5. HISTORICAL REGIONAL BENCHMARKING
-- ============================================================

SELECT *
FROM analytics.vw_regional_benchmarking
ORDER BY year DESC, regional_salary_rank;


-- ============================================================
-- 6. LATEST AVAILABLE YEAR RANKING
-- ============================================================

SELECT
    regional_salary_rank,
    region,
    regional_salary,
    national_salary,
    salary_difference_eur,
    salary_difference_pct,
    regional_salary_index,
    salary_growth_yoy_pct,
    benchmark_position

FROM analytics.vw_regional_benchmarking

WHERE year = (
    SELECT MAX(year)
    FROM analytics.vw_regional_benchmarking
)

ORDER BY regional_salary_rank;