-- The headline risk insight: does an applicant's PRIOR credit behavior (external
-- bureau debt + historical late payments on Home Credit loans) associate with
-- their CURRENT default? Joins both rollups to the outcome.
with apps as (
    select application_id, is_default from {{ ref('fct_applications') }}
),

bureau as (
    select * from {{ ref('int_bureau__applicant_rollup') }}
),

installments as (
    select * from {{ ref('int_installments__applicant_rollup') }}
),

combined as (
    select
        a.application_id,
        a.is_default,
        coalesce(b.prior_credit_count, 0)        as prior_credit_count,
        coalesce(b.total_credit_debt, 0)         as external_debt,
        coalesce(i.late_payment_rate, 0)         as late_payment_rate
    from apps a
    left join bureau b       using (application_id)
    left join installments i using (application_id)
)

select
    case
        when late_payment_rate = 0      then 'No late payments'
        when late_payment_rate <= 0.10  then 'Up to 10% late'
        when late_payment_rate <= 0.25  then '10-25% late'
        else 'Over 25% late'
    end                                               as late_payment_band,
    count(*)                                          as applicants,
    round(avg(prior_credit_count), 1)                 as avg_prior_credits,
    round(avg(external_debt), 0)                      as avg_external_debt,
    sum(is_default)                                   as defaults,
    round(safe_divide(sum(is_default), count(*)) * 100, 2) as default_rate_pct
from combined
group by late_payment_band
order by default_rate_pct desc
