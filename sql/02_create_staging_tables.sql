-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 02 - Staging Tables Creation
-- ============================================================

-- ------------------------------------------------------------
-- 1. LABOUR COSTS
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.labour_costs (

    economic_activity TEXT NOT NULL,
    cost_component TEXT NOT NULL,
    period TEXT NOT NULL,
    labour_cost NUMERIC(14,2) NOT NULL,
    year INTEGER NOT NULL,
    quarter INTEGER NOT NULL,

    PRIMARY KEY (economic_activity, cost_component, period),

    CHECK (quarter BETWEEN 1 AND 4),
    CHECK (period = year::TEXT || 'T' || quarter::TEXT)

);

-- ------------------------------------------------------------
-- 2. SALARY BY ECONOMIC ACTIVITY
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.salary_economic_activity (

    economic_activity TEXT NOT NULL,
    gender TEXT NOT NULL,
    year INTEGER NOT NULL,
    annual_salary NUMERIC(14,2) NOT NULL,

    PRIMARY KEY (economic_activity, gender, year),

    CHECK (gender IN ('All', 'Male', 'Female'))

);

-- ------------------------------------------------------------
-- 3. SALARY BY OCCUPATION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.salary_occupation (

    occupation TEXT NOT NULL,
    gender TEXT NOT NULL,
    year INTEGER NOT NULL,
    annual_salary NUMERIC(14,2),

    PRIMARY KEY (occupation, gender, year),

    CHECK (gender IN ('All', 'Male', 'Female'))

);

-- ------------------------------------------------------------
-- 4. REGIONAL SALARY BY SECTOR
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.salary_regional_sector (

    region TEXT NOT NULL,
    sector TEXT NOT NULL,
    gender TEXT NOT NULL,
    year INTEGER NOT NULL,
    annual_salary NUMERIC(14,2),

    PRIMARY KEY (region, sector, gender, year),

    CHECK (gender IN ('All', 'Male', 'Female'))

);

-- ------------------------------------------------------------
-- 5. REGIONAL SALARY BY OCCUPATION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS staging.salary_regional_occupation (

    region TEXT NOT NULL,
    occupation TEXT NOT NULL,
    gender TEXT NOT NULL,
    year INTEGER NOT NULL,
    annual_salary NUMERIC(14,2) NOT NULL,

    PRIMARY KEY (region, occupation, gender, year),

    CHECK (gender IN ('All', 'Male', 'Female'))

);

-- ============================================================
-- 6. TABLE DOCUMENTATION
-- ============================================================

COMMENT ON TABLE staging.labour_costs IS
'Quarterly labour costs by economic activity and cost component.';

COMMENT ON TABLE staging.salary_economic_activity IS
'Annual salaries by economic activity and gender.';

COMMENT ON TABLE staging.salary_occupation IS
'Annual salaries by occupation and gender.';

COMMENT ON TABLE staging.salary_regional_sector IS
'Annual salaries by region, economic sector and gender.';

COMMENT ON TABLE staging.salary_regional_occupation IS
'Annual salaries by region, occupation and gender.';

-- ============================================================
-- 7. TABLE VALIDATION
-- ============================================================

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'staging'
ORDER BY table_name;

-- ============================================================
-- QUALITY FLAG EXTENSION
-- ============================================================

BEGIN;

ALTER TABLE staging.salary_economic_activity
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE staging.salary_occupation
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE staging.salary_regional_sector
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE staging.salary_regional_occupation
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

COMMIT;

-- ============================================================
-- QUALITY FLAG VALIDATION
-- ============================================================

SELECT
    table_schema,
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_schema = 'staging'
    AND column_name = 'quality_flag'
ORDER BY table_name;