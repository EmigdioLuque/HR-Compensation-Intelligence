-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 04 - Dimension Tables
-- ============================================================

BEGIN;

-- ------------------------------------------------------------
-- 1. YEAR DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_year (
    year_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    year INTEGER NOT NULL UNIQUE
);

-- ------------------------------------------------------------
-- 2. QUARTER DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_quarter (
    quarter_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    quarter INTEGER NOT NULL UNIQUE,
    quarter_name TEXT NOT NULL,

    CHECK (quarter BETWEEN 1 AND 4)
);

-- ------------------------------------------------------------
-- 3. GENDER DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_gender (
    gender_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    gender TEXT NOT NULL UNIQUE,
    is_aggregate BOOLEAN NOT NULL,

    CHECK (gender IN ('All', 'Male', 'Female'))
);

-- ------------------------------------------------------------
-- 4. REGION DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_region (
    region_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    region_name TEXT NOT NULL UNIQUE,
    is_aggregate BOOLEAN NOT NULL
);

-- ------------------------------------------------------------
-- 5. ECONOMIC ACTIVITY DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_economic_activity (
    activity_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    activity_code TEXT NOT NULL,
    activity_name TEXT NOT NULL,
    source_dataset TEXT NOT NULL,
    is_aggregate BOOLEAN NOT NULL,

    UNIQUE (source_dataset, activity_name),

    CHECK (
        source_dataset IN ('Annual Salary', 'Labour Costs')
    )
);

-- ------------------------------------------------------------
-- 6. NATIONAL OCCUPATION DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_national_occupation (
    occupation_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occupation_name TEXT NOT NULL UNIQUE,
    is_aggregate BOOLEAN NOT NULL
);

-- ------------------------------------------------------------
-- 7. REGIONAL OCCUPATION DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_regional_occupation (
    occupation_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    occupation_level TEXT NOT NULL UNIQUE,
    is_aggregate BOOLEAN NOT NULL
);

-- ------------------------------------------------------------
-- 8. ECONOMIC SECTOR DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_sector (
    sector_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    sector_name TEXT NOT NULL UNIQUE,
    is_aggregate BOOLEAN NOT NULL
);

-- ------------------------------------------------------------
-- 9. COST COMPONENT DIMENSION
-- ------------------------------------------------------------

CREATE TABLE IF NOT EXISTS warehouse.dim_cost_component (
    component_id INTEGER GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    component_name TEXT NOT NULL UNIQUE
);

COMMIT;

-- ============================================================
-- 10. DIMENSION TABLE VALIDATION
-- ============================================================

SELECT
    table_schema,
    table_name,
    table_type
FROM information_schema.tables
WHERE table_schema = 'warehouse'
ORDER BY table_name;