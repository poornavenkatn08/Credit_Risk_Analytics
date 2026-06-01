-- Collapses each applicant's external credit history (many bureau rows) down to
-- one row per application_id. These are classic credit-risk features: how much
-- outstanding debt, how many active lines, any overdue balances.
with bureau as (
    select * from {{ ref('stg_home_credit__bureau') }}
)

select
    application_id,
    count(*)                                              as prior_credit_count,
    countif(credit_status = 'Active')                     as active_credit_count,
    countif(credit_status = 'Bad debt')                   as bad_debt_count,
    sum(credit_sum)                                       as total_credit_sum,
    sum(coalesce(credit_debt, 0))                         as total_credit_debt,
    sum(coalesce(credit_overdue, 0))                      as total_credit_overdue,
    max(days_overdue)                                     as max_days_overdue
from bureau
group by application_id
