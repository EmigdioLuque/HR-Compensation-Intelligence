# Data Dictionary

## 1. Overview

This document describes the principal data structures
used by the HR Compensation Intelligence platform.

The PostgreSQL database contains three working schemas:

| Schema | Object Type | Objects |
|---|---|---:|
| staging | Base tables | 5 |
| warehouse | Base tables | 14 |
| analytics | SQL views | 11 |
| Total | Database objects | 30 |

## 2. Source Datasets

| INE Dataset ID | Analytical Domain | Records |
|---|---|---:|
| 6032 | Labour costs by economic activity | 16,872 |
| 28185 | Annual salaries by economic activity | 969 |
| 28186 | Annual salaries by occupation | 918 |
| 28192 | Regional salaries by sector | 3,672 |
| 28193 | Regional salaries by occupation | 3,672 |
| Total | | 26,103 |

## 3. Dimension Tables

Dimension tables contain descriptive attributes used to
classify and contextualise statistical observations.

| Table | Description |
|---|---|
| dim_cost_component | Labour cost components |
| dim_economic_activity | Economic activity classifications |
| dim_gender | Gender categories |
| dim_national_occupation | National occupational classifications |
| dim_quarter | Quarterly reference periods |
| dim_region | Spanish geographical regions |
| dim_regional_occupation | Regional occupational classifications |
| dim_sector | Economic sector classifications |
| dim_year | Annual reference periods |

## 4. Fact Tables

Fact tables contain quantitative statistical observations
associated with the relevant dimensions.

| Table | Analytical Content | Records |
|---|---|---:|
| fact_labour_costs | Quarterly labour cost observations | 16,872 |
| fact_salary_economic_activity | Annual salary by economic activity | 969 |
| fact_salary_occupation | Annual salary by occupation | 918 |
| fact_salary_regional_occupation | Regional salary by occupation | 3,672 |
| fact_salary_regional_sector | Regional salary by sector | 3,672 |

## 5. Principal Data Fields

| Field | Description |
|---|---|
| activity_id | Economic activity identifier |
| component_id | Labour cost component identifier |
| gender_id | Gender category identifier |
| year_id | Annual reference period identifier |
| quarter_id | Quarterly reference period identifier |
| annual_salary | Reported annual gross earnings in euros |
| labour_cost | Reported labour cost observation |
| quality_flag | Statistical quality information associated with an observation |

## 6. Executive Overview Metrics

The executive overview view provides national compensation
indicators and historical salary comparisons.

| Field | Definition |
|---|---|
| year | Reference year |
| average_salary | National average annual gross salary |
| male_salary | Average annual gross salary for men |
| female_salary | Average annual gross salary for women |
| previous_year_salary | National salary in the previous year |
| annual_salary_change | Absolute annual salary variation |
| salary_growth_pct | Annual salary growth percentage |
| gender_pay_gap_eur | Absolute difference between male and female earnings |
| gender_pay_gap_pct | Unadjusted gender earnings gap percentage |

## 7. Data Coverage

| Data Domain | Reference Period |
|---|---|
| Annual salary statistics | 2008-2024 |
| Quarterly labour cost statistics | 2008-2026 Q2 |
| Geographical market | Spain |
| Monetary currency | EUR |

## 8. Data Granularity

The warehouse preserves the different levels of aggregation
provided by the original statistical datasets.

Annual salary observations and quarterly labour cost
observations are stored and analysed separately.

National and regional occupational classifications are
maintained as separate dimensions.

## 9. Missing Observations

Unavailable salary observations are represented by NULL
values rather than being automatically replaced with zero.

Statistical quality flags should be considered when
interpreting individual observations.

## 10. Database Integrity

The warehouse includes:

- 14 primary key constraints.
- 18 foreign key constraints.
- 9 unique constraints.
- 53 constraints reported under the CHECK category.

The database structure supports consistent relationships
between dimensions and fact tables.

## 11. Documentation Scope

This document describes the principal logical data model
and business fields.

The complete physical database structure is defined
by the SQL scripts and PostgreSQL metadata.