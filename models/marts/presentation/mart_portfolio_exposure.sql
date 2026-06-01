-- Portfolio exposure and risk by loan product and income band: how much money
-- is lent, the average ticket, and the realized default rate. Risk-weighted view.
with apps as (
    select * from {{ ref('fct_applications') }}
),

applicants as (
    select application_id, income_band from {{ ref('dim_applicants') }}
)

select
    a.contract_type,
    ap.income_band,
    count(*)                                          as loans,
    round(sum(a.credit_amount), 0)                    as total_exposure,
    round(avg(a.credit_amount), 0)                    as avg_loan_size,
    round(avg(a.credit_to_income_ratio), 2)           as avg_credit_to_income,
    round(safe_divide(sum(a.is_default), count(*)) * 100, 2) as default_rate_pct
from apps a
inner join applicants ap using (application_id)
group by a.contract_type, ap.income_band
order by total_exposure desc
