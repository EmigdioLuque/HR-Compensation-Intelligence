-- ============================================================
-- HR COMPENSATION INTELLIGENCE
-- 01 - Database Schema Creation
-- ============================================================

-- 1. Staging layer

CREATE SCHEMA IF NOT EXISTS staging;

-- 2. Data warehouse layer

CREATE SCHEMA IF NOT EXISTS warehouse;

-- 3. Analytics layer

CREATE SCHEMA IF NOT EXISTS analytics;

-- ============================================================
-- SCHEMA DOCUMENTATION
-- ============================================================

COMMENT ON SCHEMA staging IS
'Initial storage of processed INE datasets.';

COMMENT ON SCHEMA warehouse IS
'Structured dimensional model containing fact and dimension tables.';

COMMENT ON SCHEMA analytics IS
'Analytical views and business intelligence indicators.';

-- ============================================================
-- SCHEMA VALIDATION
-- ============================================================

SELECT
    schema_name,
    schema_owner
FROM information_schema.schemata
WHERE schema_name IN (
    'staging',
    'warehouse',
    'analytics'
)
ORDER BY schema_name;