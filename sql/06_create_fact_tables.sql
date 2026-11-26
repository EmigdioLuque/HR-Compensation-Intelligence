-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 06 - Create Fact Tables
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. LABOUR COSTS FACT TABLE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.fact_labour_costs (

    activity_id INTEGER NOT NULL,
    component_id INTEGER NOT NULL,
    year_id INTEGER NOT NULL,
    quarter_id INTEGER NOT NULL,

    labour_cost NUMERIC(14,2) NOT NULL,

    PRIMARY KEY (
        activity_id,
        component_id,
        year_id,
        quarter_id
    ),

    FOREIGN KEY (activity_id)
        REFERENCES warehouse.dim_economic_activity(activity_id),

    FOREIGN KEY (component_id)
        REFERENCES warehouse.dim_cost_component(component_id),

    FOREIGN KEY (year_id)
        REFERENCES warehouse.dim_year(year_id),

    FOREIGN KEY (quarter_id)
        REFERENCES warehouse.dim_quarter(quarter_id)

);

-- ------------------------------------------------------------
-- 2. SALARY BY ECONOMIC ACTIVITY FACT TABLE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.fact_salary_economic_activity (

    activity_id INTEGER NOT NULL,
    gender_id INTEGER NOT NULL,
    year_id INTEGER NOT NULL,

    annual_salary NUMERIC(14,2),

    PRIMARY KEY (
        activity_id,
        gender_id,
        year_id
    ),

    FOREIGN KEY (activity_id)
        REFERENCES warehouse.dim_economic_activity(activity_id),

    FOREIGN KEY (gender_id)
        REFERENCES warehouse.dim_gender(gender_id),

    FOREIGN KEY (year_id)
        REFERENCES warehouse.dim_year(year_id),

    CHECK (annual_salary >= 0)

);

-- ------------------------------------------------------------
-- 3. SALARY BY OCCUPATION FACT TABLE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.fact_salary_occupation (

    occupation_id INTEGER NOT NULL,
    gender_id INTEGER NOT NULL,
    year_id INTEGER NOT NULL,

    annual_salary NUMERIC(14,2),

    PRIMARY KEY (
        occupation_id,
        gender_id,
        year_id
    ),

    FOREIGN KEY (occupation_id)
        REFERENCES warehouse.dim_national_occupation(occupation_id),

    FOREIGN KEY (gender_id)
        REFERENCES warehouse.dim_gender(gender_id),

    FOREIGN KEY (year_id)
        REFERENCES warehouse.dim_year(year_id),

    CHECK (annual_salary >= 0)

);

-- ------------------------------------------------------------
-- 4. REGIONAL SALARY BY SECTOR FACT TABLE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.fact_salary_regional_sector (

    region_id INTEGER NOT NULL,
    sector_id INTEGER NOT NULL,
    gender_id INTEGER NOT NULL,
    year_id INTEGER NOT NULL,

    annual_salary NUMERIC(14,2),

    PRIMARY KEY (
        region_id,
        sector_id,
        gender_id,
        year_id
    ),

    FOREIGN KEY (region_id)
        REFERENCES warehouse.dim_region(region_id),

    FOREIGN KEY (sector_id)
        REFERENCES warehouse.dim_sector(sector_id),

    FOREIGN KEY (gender_id)
        REFERENCES warehouse.dim_gender(gender_id),

    FOREIGN KEY (year_id)
        REFERENCES warehouse.dim_year(year_id),

    CHECK (annual_salary >= 0)

);

-- ------------------------------------------------------------
-- 5. REGIONAL SALARY BY OCCUPATION FACT TABLE
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.fact_salary_regional_occupation (

    region_id INTEGER NOT NULL,
    occupation_id INTEGER NOT NULL,
    gender_id INTEGER NOT NULL,
    year_id INTEGER NOT NULL,

    annual_salary NUMERIC(14,2),

    PRIMARY KEY (
        region_id,
        occupation_id,
        gender_id,
        year_id
    ),

    FOREIGN KEY (region_id)
        REFERENCES warehouse.dim_region(region_id),

    FOREIGN KEY (occupation_id)
        REFERENCES warehouse.dim_regional_occupation(occupation_id),

    FOREIGN KEY (gender_id)
        REFERENCES warehouse.dim_gender(gender_id),

    FOREIGN KEY (year_id)
        REFERENCES warehouse.dim_year(year_id),

    CHECK (annual_salary >= 0)

);

COMMIT;

-- ============================================================
-- 6. FACT TABLE VALIDATION
-- ============================================================

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'warehouse'
    AND table_name LIKE 'fact_%'
ORDER BY table_name;

-- ============================================================
-- QUALITY FLAG EXTENSION - FACT TABLES
-- ============================================================

BEGIN;

ALTER TABLE warehouse.fact_salary_economic_activity
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE warehouse.fact_salary_occupation
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE warehouse.fact_salary_regional_sector
ADD COLUMN IF NOT EXISTS quality_flag TEXT;

ALTER TABLE warehouse.fact_salary_regional_occupation
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
WHERE table_schema = 'warehouse'
    AND column_name = 'quality_flag'
ORDER BY table_name;