# Data Quality and Validation Report

## 1. Executive Summary

Data quality validation was performed directly against
the PostgreSQL data warehouse to assess data completeness,
record counts, duplicate observations and database integrity.

Validation date: 26 November 2026.

## 2. Quality Overview

| Quality Indicator | Result |
|---|---:|
| Source datasets | 5 |
| Total fact records | 26,103 |
| Non-null observations | 25,845 |
| Missing observations | 258 |
| Overall completeness | 99.01% |
| Detected duplicate records | 0 |
| Fact tables | 5 |
| Dimension tables | 9 |
| Analytical views | 11 |

## 3. Dataset-Level Validation

| Dataset | Total | Non-null | Missing | Completeness |
|---|---:|---:|---:|---:|
| Labour costs | 16,872 | 16,872 | 0 | 100.00% |
| Salary by economic activity | 969 | 969 | 0 | 100.00% |
| Salary by occupation | 918 | 856 | 62 | 93.25% |
| Regional salary by occupation | 3,672 | 3,672 | 0 | 100.00% |
| Regional salary by sector | 3,672 | 3,476 | 196 | 94.66% |
| Total | 26,103 | 25,845 | 258 | 99.01% |

## 4. Missing Data Management

Missing observations are preserved as NULL values.

They are not automatically replaced with zero or estimated
through statistical imputation.

This approach prevents unavailable statistical observations
from being interpreted as actual zero earnings.

The presence of missing observations is acknowledged
as a limitation of the available source data.

## 5. Duplicate Validation

Duplicate checks were performed across the five fact tables,
excluding the quantitative measure and applicable quality flag
from the observation comparison.

| Fact Table | Detected Duplicates |
|---|---:|
| fact_labour_costs | 0 |
| fact_salary_economic_activity | 0 |
| fact_salary_occupation | 0 |
| fact_salary_regional_occupation | 0 |
| fact_salary_regional_sector | 0 |

No duplicate observations were detected by the implemented checks.

## 6. Database Integrity

PostgreSQL metadata was inspected to verify the presence
of database constraints.

| Constraint Category | Count |
|---|---:|
| Primary key | 14 |
| Foreign key | 18 |
| Unique | 9 |
| Check | 53 |
| Total | 94 |

These counts reflect the categories reported by
PostgreSQL information_schema metadata.

## 7. Analytical Validation

The executive overview analytical view was queried directly
to verify consistency with the application dashboard.

### Reference Year: 2024

| Indicator | Validated Value |
|---|---:|
| National average annual salary | EUR 29,540.26 |
| Average male annual salary | EUR 32,057.55 |
| Average female annual salary | EUR 26,904.90 |
| Previous year salary | EUR 28,049.94 |
| Annual salary increase | EUR 1,490.32 |
| Annual salary growth | 5.31% |
| Gender earnings difference | EUR 5,152.65 |
| Unadjusted gender pay gap | 16.07% |

The reviewed indicators are consistent with the
values displayed in the Executive Overview module.

## 8. Temporal Validation

The executive overview contains 17 annual observations
covering the period from 2008 to 2024.

Previous-year metrics are unavailable for the first
reference year and are therefore represented as NULL.

## 9. Validation Queries

### Database Inventory

```sql
SELECT
    table_schema,
    table_type,
    COUNT(*) AS total_objects
FROM information_schema.tables
WHERE table_schema IN (
    'staging',
    'warehouse',
    'analytics'
)
GROUP BY table_schema, table_type
ORDER BY table_schema;
```

### Database Constraints

```sql
SELECT
    constraint_type,
    COUNT(*) AS total_constraints
FROM information_schema.table_constraints
WHERE table_schema = 'warehouse'
GROUP BY constraint_type
ORDER BY constraint_type;
```

### Executive Overview Validation

```sql
SELECT *
FROM analytics.vw_executive_overview
WHERE year = 2024;
```

## 10. Quality Limitations

- Completeness measures the availability of non-null values,
  not the statistical accuracy of every observation.
- Source observations may contain statistical quality flags.
- Aggregate salary statistics do not represent individual salaries.
- The implemented duplicate checks do not replace a full source audit.
- Validation of selected indicators does not establish that
  every analytical calculation is error-free.

## 11. Conclusion

The reviewed database contains 26,103 fact records,
with 99.01% non-null completeness and no duplicates
detected by the implemented checks.

The validation provides a documented foundation for
the analytical platform and its portfolio presentation.