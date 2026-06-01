
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
