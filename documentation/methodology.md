# Analytical Methodology

## 1. Research Objective

HR Compensation Intelligence provides an analytical
framework for understanding salary dynamics, compensation
differences and workforce expenditure in Spain.

The platform is designed to support exploratory analysis,
compensation benchmarking and illustrative workforce planning.

## 2. Official Data Sources

All statistical source datasets originate from the
Instituto Nacional de Estadistica (INE).

| Dataset | Source |
|---|---|
| Labour costs by economic activity | [INE 6032](https://www.ine.es/jaxiT3/Tabla.htm?t=6032) |
| Annual salaries by economic activity | [INE 28185](https://www.ine.es/jaxiT3/Tabla.htm?t=28185) |
| Annual salaries by occupation | [INE 28186](https://www.ine.es/jaxiT3/Tabla.htm?t=28186) |
| Regional salaries by sector | [INE 28192](https://www.ine.es/jaxiT3/Tabla.htm?t=28192) |
| Regional salaries by occupation | [INE 28193](https://www.ine.es/jaxiT3/Tabla.htm?t=28193) |

Official statistical provider:

https://www.ine.es/

## 3. Average Annual Salary

Average annual salary represents the reported mean
annual gross earnings for the selected statistical category.

The platform uses published aggregate salary observations.

It does not estimate individual employee salaries.

## 4. Annual Salary Growth

Annual salary growth measures the percentage change
in reported earnings relative to the previous year.

Formula:

    Salary Growth (%) =
    ((Current Salary / Previous Salary) - 1) x 100

Absolute salary change:

    Salary Change (EUR) =
    Current Salary - Previous Salary

Salary growth is expressed in nominal terms and is not
adjusted for inflation.

## 5. Salary Benchmark Index

The salary benchmark index compares the earnings of a
selected category against the relevant national salary.

Formula:

    Benchmark Index =
    (Category Salary / National Salary) x 100

Interpretation:

- Above 100: salary above the national benchmark.
- Equal to 100: salary equal to the national benchmark.
- Below 100: salary below the national benchmark.

The benchmark must refer to a comparable reference period
and statistical population.

## 6. Regional Benchmarking

Regional analysis compares published compensation
observations across Spanish autonomous communities.

The analytical approach supports:

- Regional salary comparisons.
- Differences relative to national earnings.
- Historical regional salary evolution.
- Regional compensation rankings.

Regional averages are not interpreted as individual
salary expectations or cost-of-living-adjusted earnings.

## 7. Sector and Occupational Analysis

Sector and occupational modules compare reported
annual earnings across economic activities and
occupational classifications.

The platform preserves the classifications and
aggregation levels of the original statistical datasets.

National and regional occupational classifications
are not assumed to be directly interchangeable.

## 8. Gender Pay Gap

The platform calculates an unadjusted annual
gender earnings gap.

Formula:

    Gender Pay Gap (%) =
    ((Male Salary - Female Salary) / Male Salary) x 100

Absolute earnings difference:

    Earnings Difference (EUR) =
    Male Salary - Female Salary

A positive percentage indicates higher reported
average male earnings.

This indicator is not adjusted for working hours,
occupation, seniority, education, experience or
other explanatory variables.

It must not be interpreted as a direct measure of
pay discrimination or unequal pay for identical work.

## 9. Labour Cost Intelligence

Labour cost analysis examines the reported cost
components associated with employment.

Annual salary statistics and quarterly labour cost
statistics are analysed separately.

The non-salary cost ratio is calculated as:

    Non-Salary Cost Ratio (%) =
    (Non-Salary Cost / Salary Cost) x 100

The ratio provides an aggregate benchmark for
illustrative workforce cost estimation.

## 10. Workforce Cost Simulator

The simulator estimates workforce expenditure
under user-defined compensation assumptions.

### Input Variables

- Number of employees.
- Annual gross salary per employee.
- Economic activity.
- Labour cost benchmark period.
- Non-salary cost assumption.
- Projected salary adjustment.
- Additional annual cost per employee.

### Current Workforce Budget

    Gross Salary Budget =
    Employees x Annual Gross Salary

    Estimated Non-Salary Costs =
    Gross Salary Budget x Non-Salary Cost Ratio

    Additional Costs =
    Employees x Additional Cost per Employee

    Total Workforce Budget =
    Gross Salary Budget
    + Estimated Non-Salary Costs
    + Additional Costs

### Projected Workforce Budget

    Projected Salary =
    Current Salary x (1 + Salary Adjustment)

    Projected Gross Salary Budget =
    Employees x Projected Salary

    Projected Workforce Budget =
    Projected Gross Salary Budget
    + Projected Non-Salary Costs
    + Additional Costs

### Budget Impact

    Annual Budget Impact =
    Projected Workforce Budget - Current Workforce Budget

    Projected Monthly Budget =
    Projected Workforce Budget / 12

Percentage inputs are converted into decimal ratios
before applying the formulas.

The simulator assumes a constant workforce size
and non-salary cost ratio between scenarios.

## 11. Missing Data and Statistical Quality

Unavailable observations are preserved as NULL values.

Missing observations are not automatically treated as
zero or replaced through statistical imputation.

Published estimates may contain statistical quality flags,
which should be considered during interpretation.

## 12. Analytical Limitations

- Salary figures represent aggregated statistical observations.
- Salary changes are not adjusted for inflation.
- Regional comparisons do not account for living costs.
- The gender earnings gap is unadjusted.
- Statistical classifications may differ between datasets.
- Annual and quarterly observations have different frequencies.
- Workforce simulations depend on simplified assumptions.
- Estimated employer costs may differ from actual payroll costs.

## 13. Intended Use

The platform is intended for:

- Compensation benchmarking.
- Labour market research.
- People Analytics exploration.
- Illustrative workforce budget planning.
- Business Intelligence portfolio demonstration.

It is not a substitute for professional payroll,
legal or employment compliance advice.

## 14. Project Statement

HR Compensation Intelligence is an independent
Business Intelligence and People Analytics project.

It is not affiliated with or endorsed by INE
or any commercial organisation.