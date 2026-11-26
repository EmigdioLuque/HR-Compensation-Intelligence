-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 15 - Labour Cost Intelligence
-- ============================================================

BEGIN;

-- ============================================================
-- 1. CREATE LABOUR COST INTELLIGENCE VIEW
-- ============================================================

CREATE OR REPLACE VIEW analytics.vw_labour_cost_intelligence AS

WITH cost_structure AS (

    SELECT
        year,
        quarter,
        period,
        economic_activity,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Coste laboral total'
        ) AS total_labour_cost,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Coste salarial total'
        ) AS salary_cost,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Otros costes'
        ) AS non_salary_cost,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Coste por cotizaciones obligatorias'
        ) AS employer_contributions,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Coste salarial ordinario'
        ) AS ordinary_salary_cost,

        MAX(labour_cost) FILTER (
            WHERE cost_component = 'Coste salarial extraordinario'
        ) AS extraordinary_salary_cost

    FROM analytics.vw_labour_costs

    GROUP BY
        year,
        quarter,
        period,
        economic_activity

),

-- ------------------------------------------------------------
-- 2. NATIONAL BENCHMARK
-- ------------------------------------------------------------

national_benchmark AS (

    SELECT
        year,
        quarter,
        total_labour_cost AS national_labour_cost

    FROM cost_structure

    WHERE LEFT(economic_activity, 4) = 'B_S '

),

-- ------------------------------------------------------------
-- 3. HISTORICAL COMPARISONS
-- ------------------------------------------------------------

historical_comparison AS (

    SELECT
        c.*,

        previous_quarter.total_labour_cost
            AS previous_quarter_cost,

        previous_year.total_labour_cost
            AS previous_year_cost

    FROM cost_structure c

    LEFT JOIN cost_structure previous_quarter
        ON c.economic_activity = previous_quarter.economic_activity
        AND (
            c.year * 4 + c.quarter
            =
            previous_quarter.year * 4
            + previous_quarter.quarter + 1
        )

    LEFT JOIN cost_structure previous_year
        ON c.economic_activity = previous_year.economic_activity
        AND c.year = previous_year.year + 1
        AND c.quarter = previous_year.quarter

),

-- ------------------------------------------------------------
-- 4. ECONOMIC ACTIVITY RANKING
-- ------------------------------------------------------------

activity_ranking AS (

    SELECT
        year,
        quarter,
        economic_activity,

        DENSE_RANK() OVER (
            PARTITION BY year, quarter
            ORDER BY total_labour_cost DESC NULLS LAST
        ) AS labour_cost_rank

    FROM cost_structure

    WHERE LEFT(economic_activity, 4) <> 'B_S '
        AND total_labour_cost IS NOT NULL

)

-- ============================================================
-- 5. FINAL ANALYTICAL OUTPUT
-- ============================================================

SELECT
    h.year,
    h.quarter,
    h.period,
    h.economic_activity,

    CASE
        WHEN LEFT(h.economic_activity, 4) = 'B_S '
            THEN 'National'
        ELSE 'Economic Activity'
    END AS analysis_type,

    r.labour_cost_rank,

    -- Cost structure

    h.total_labour_cost,
    h.salary_cost,
    h.non_salary_cost,
    h.employer_contributions,
    h.ordinary_salary_cost,
    h.extraordinary_salary_cost,

    -- Cost composition

    ROUND(
        100.0 * h.salary_cost
        / NULLIF(h.total_labour_cost, 0),
        2
    ) AS salary_cost_share_pct,

    ROUND(
        100.0 * h.non_salary_cost
        / NULLIF(h.total_labour_cost, 0),
        2
    ) AS non_salary_cost_share_pct,

    ROUND(
        100.0 * h.employer_contributions
        / NULLIF(h.total_labour_cost, 0),
        2
    ) AS employer_contributions_share_pct,

    -- National benchmarking

    n.national_labour_cost,

    ROUND(
        h.total_labour_cost - n.national_labour_cost,
        2
    ) AS labour_cost_difference_eur,

    ROUND(
        100.0 * (
            h.total_labour_cost - n.national_labour_cost
        ) / NULLIF(n.national_labour_cost, 0),
        2
    ) AS labour_cost_difference_pct,

    ROUND(
        100.0 * h.total_labour_cost
        / NULLIF(n.national_labour_cost, 0),
        2
    ) AS labour_cost_index,

    -- Historical comparisons

    h.previous_quarter_cost,
    h.previous_year_cost,

    ROUND(
        h.total_labour_cost - h.previous_quarter_cost,
        2
    ) AS quarterly_cost_change_eur,

    ROUND(
        100.0 * (
            h.total_labour_cost - h.previous_quarter_cost
        ) / NULLIF(h.previous_quarter_cost, 0),
        2
    ) AS labour_cost_growth_qoq_pct,

    ROUND(
        h.total_labour_cost - h.previous_year_cost,
        2
    ) AS annual_cost_change_eur,

    ROUND(
        100.0 * (
            h.total_labour_cost - h.previous_year_cost
        ) / NULLIF(h.previous_year_cost, 0),
        2
    ) AS labour_cost_growth_yoy_pct,

    -- Benchmark classification

    CASE

        WHEN h.total_labour_cost IS NULL
            OR n.national_labour_cost IS NULL
            THEN 'Unavailable'

        WHEN h.total_labour_cost > n.national_labour_cost
            THEN 'Above National Average'

        WHEN h.total_labour_cost < n.national_labour_cost
            THEN 'Below National Average'

        ELSE 'National Average'

    END AS benchmark_position,

    -- Annual cost trend

    CASE

        WHEN h.previous_year_cost IS NULL
            OR h.total_labour_cost IS NULL
            THEN 'Unavailable'

        WHEN h.total_labour_cost > h.previous_year_cost
            THEN 'Increasing'

        WHEN h.total_labour_cost < h.previous_year_cost
            THEN 'Decreasing'

        ELSE 'Stable'

    END AS labour_cost_trend

FROM historical_comparison h

LEFT JOIN national_benchmark n
    ON h.year = n.year
    AND h.quarter = n.quarter

LEFT JOIN activity_ranking r
    ON h.year = r.year
    AND h.quarter = r.quarter
    AND h.economic_activity = r.economic_activity;


COMMIT;


-- ============================================================
-- 6. VIEW COVERAGE VALIDATION
-- ============================================================

SELECT
    COUNT(*) AS total_records,
    COUNT(DISTINCT economic_activity) AS total_activities,
    COUNT(DISTINCT period) AS total_periods,
    MIN(year) AS first_year,
    MAX(year) AS latest_year,

    COUNT(*) FILTER (
        WHERE total_labour_cost IS NULL
    ) AS missing_total_costs,

    COUNT(*) FILTER (
        WHERE national_labour_cost IS NULL
    ) AS missing_benchmarks

FROM analytics.vw_labour_cost_intelligence;


-- ============================================================
-- 7. NATIONAL LABOUR COST OVERVIEW
-- ============================================================

SELECT
    period,
    total_labour_cost,
    salary_cost,
    non_salary_cost,
    employer_contributions,
    salary_cost_share_pct,
    non_salary_cost_share_pct,
    labour_cost_growth_qoq_pct,
    labour_cost_growth_yoy_pct,
    labour_cost_trend

FROM analytics.vw_labour_cost_intelligence

WHERE analysis_type = 'National'

ORDER BY year DESC, quarter DESC

LIMIT 1;


-- ============================================================
-- 8. LATEST ECONOMIC ACTIVITY RANKING
-- ============================================================

SELECT
    period,
    labour_cost_rank,
    economic_activity,
    total_labour_cost,
    salary_cost,
    non_salary_cost,
    national_labour_cost,
    labour_cost_difference_pct,
    labour_cost_index,
    labour_cost_growth_yoy_pct,
    benchmark_position,
    labour_cost_trend

FROM analytics.vw_labour_cost_intelligence

WHERE analysis_type = 'Economic Activity'

    AND (year, quarter) = (

        SELECT year, quarter

        FROM analytics.vw_labour_cost_intelligence

        ORDER BY year DESC, quarter DESC

        LIMIT 1

    )

ORDER BY labour_cost_rank;