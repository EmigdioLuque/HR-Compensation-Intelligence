-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 10 - Executive Overview
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. NATIONAL SALARY INDICATORS
-- ------------------------------------------------------------

CREATE OR REPLACE VIEW analytics.vw_executive_overview AS

WITH national_salary AS (

    SELECT
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

    FROM analytics.vw_salary_economic_activity

    WHERE economic_activity = 'B_S Todas las secciones'
        AND quality_flag = 'STANDARD'

    GROUP BY year

),

salary_evolution AS (

    SELECT
        year,
        average_salary,
        male_salary,
        female_salary,

        LAG(average_salary) OVER (
            ORDER BY year
        ) AS previous_year_salary,

        LAG(year) OVER (
            ORDER BY year
        ) AS previous_year

    FROM national_salary

)

SELECT
    year,

    ROUND(average_salary, 2) AS average_salary,

    ROUND(male_salary, 2) AS male_salary,

    ROUND(female_salary, 2) AS female_salary,

    ROUND(previous_year_salary, 2) AS previous_year_salary,

    CASE
        WHEN year - previous_year = 1
        THEN ROUND(
            average_salary - previous_year_salary,
            2
        )
    END AS annual_salary_change,

    CASE
        WHEN year - previous_year = 1
        THEN ROUND(
            (
                (average_salary - previous_year_salary)
                / NULLIF(previous_year_salary, 0)
            ) * 100,
            2
        )
    END AS salary_growth_pct,

    ROUND(
        male_salary - female_salary,
        2
    ) AS gender_pay_gap_eur,

    ROUND(
        (
            (male_salary - female_salary)
            / NULLIF(male_salary, 0)
        ) * 100,
        2
    ) AS gender_pay_gap_pct

FROM salary_evolution;

COMMIT;

-- ============================================================
-- 2. HISTORICAL EXECUTIVE OVERVIEW
-- ============================================================

SELECT *
FROM analytics.vw_executive_overview
ORDER BY year DESC;

-- ============================================================
-- 3. LATEST AVAILABLE YEAR
-- ============================================================

SELECT *
FROM analytics.vw_executive_overview
ORDER BY year DESC
LIMIT 1;