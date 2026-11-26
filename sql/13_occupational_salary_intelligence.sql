-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 13 - Occupational Salary Intelligence
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_occupational_salary_intelligence AS

-- ------------------------------------------------------------
-- 1. BASE OCCUPATIONAL DATA
-- ------------------------------------------------------------

WITH base_data AS (

    SELECT
        occupation,
        gender,
        year,
        annual_salary

    FROM analytics.vw_salary_occupation

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

    WHERE occupation = 'Todas las ocupaciones'
        AND gender = 'All'

),

-- ------------------------------------------------------------
-- 3. SALARY BY OCCUPATION
-- ------------------------------------------------------------

occupation_data AS (

    SELECT
        occupation,
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

    WHERE occupation <> 'Todas las ocupaciones'

    GROUP BY
        occupation,
        year

),

-- ------------------------------------------------------------
-- 4. HISTORICAL SALARY EVOLUTION
-- ------------------------------------------------------------

occupation_history AS (

    SELECT
        *,

        LAG(average_salary) OVER (
            PARTITION BY occupation
            ORDER BY year
        ) AS previous_year_salary,

        LAG(year) OVER (
            PARTITION BY occupation
            ORDER BY year
        ) AS previous_year

    FROM occupation_data

),

-- ------------------------------------------------------------
-- 5. OCCUPATIONAL SALARY METRICS
-- ------------------------------------------------------------

occupation_metrics AS (

    SELECT
        o.occupation,
        o.year,
        o.average_salary,
        o.male_salary,
        o.female_salary,
        n.national_salary,
        o.previous_year_salary,

        -- Salary difference against national average

        ROUND(
            o.average_salary - n.national_salary,
            2
        ) AS salary_difference_eur,

        ROUND(
            100.0 *
            (o.average_salary - n.national_salary)
            / NULLIF(n.national_salary, 0),
            2
        ) AS salary_difference_pct,

        -- Occupational salary index

        ROUND(
            100.0 * o.average_salary
            / NULLIF(n.national_salary, 0),
            2
        ) AS occupational_salary_index,

        -- Annual salary growth

        CASE
            WHEN o.previous_year = o.year - 1
            THEN ROUND(
                100.0 *
                (o.average_salary - o.previous_year_salary)
                / NULLIF(o.previous_year_salary, 0),
                2
            )
        END AS salary_growth_yoy_pct,

        -- Gender pay gap in euros

        ROUND(
            o.male_salary - o.female_salary,
            2
        ) AS gender_pay_gap_eur,

        -- Unadjusted gender pay gap percentage

        ROUND(
            100.0 *
            (o.male_salary - o.female_salary)
            / NULLIF(o.male_salary, 0),
            2
        ) AS gender_pay_gap_pct

    FROM occupation_history o

    INNER JOIN national_benchmark n
        ON o.year = n.year

    WHERE o.average_salary IS NOT NULL

)

-- ------------------------------------------------------------
-- 6. OCCUPATIONAL RANKING AND CLASSIFICATION
-- ------------------------------------------------------------

SELECT
    *,

    DENSE_RANK() OVER (
        PARTITION BY year
        ORDER BY average_salary DESC
    ) AS occupational_salary_rank,

    CASE

        WHEN average_salary > national_salary
            THEN 'Above National Average'

        WHEN average_salary < national_salary
            THEN 'Below National Average'

        ELSE 'Equal to National Average'

    END AS benchmark_position

FROM occupation_metrics;


-- ============================================================
-- 7. HISTORICAL OCCUPATIONAL ANALYSIS
-- ============================================================

SELECT *
FROM analytics.vw_occupational_salary_intelligence
ORDER BY year DESC, occupational_salary_rank;


-- ============================================================
-- 8. LATEST AVAILABLE YEAR RANKING
-- ============================================================

SELECT
    year,
    occupational_salary_rank,
    occupation,
    average_salary,
    national_salary,
    salary_difference_eur,
    salary_difference_pct,
    occupational_salary_index,
    salary_growth_yoy_pct,
    gender_pay_gap_pct,
    benchmark_position

FROM analytics.vw_occupational_salary_intelligence

WHERE year = (

    SELECT MAX(year)
    FROM analytics.vw_occupational_salary_intelligence

)

ORDER BY occupational_salary_rank;