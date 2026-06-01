-- KPI definitions (portfolio risk metrics).
--
-- These were previously expressed in a dbt MetricFlow semantic layer, but that
-- layer requires a time-spine model, which this dataset cannot provide (Home
-- Credit anonymizes all dates as integer day-offsets -- there are no calendar
-- dates). Rather than fake a time dimension, the canonical metric logic lives
-- here as a documented, runnable query and in the presentation marts.
--
-- Run ad hoc with:  dbt compile -s kpi_definitions   (then run the compiled SQL)
-- or just copy into the BigQuery console.

with apps as (
    select * from {{ ref('fct_applications') }}
)

select
    count(*)                                                   as total_applications,
    sum(is_default)                                            as total_defaults,
    -- Default Rate = defaults / applications  (the headline risk KPI; ~8%)
    round(safe_divide(sum(is_default), count(*)), 4)           as default_rate,
    -- Total Exposure = sum of credit lent
    round(sum(credit_amount), 0)                               as total_exposure,
    -- Avg Credit-to-Income  (AVG, never SUM)
    round(avg(credit_to_income_ratio), 3)                      as avg_credit_to_income
from apps
