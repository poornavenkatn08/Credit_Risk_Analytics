-- Collapses prior-loan payment history (many installment rows) to one row per
-- application_id. Captures historical repayment discipline: how often late, how
-- late on average, how much was underpaid.
with installments as (
    select * from {{ ref('stg_home_credit__installments') }}
    where days_paid is not null            -- exclude installments with no recorded payment
)

select
    application_id,
    count(*)                                              as installment_count,
    countif(days_late > 0)                                as late_payment_count,
    round(safe_divide(countif(days_late > 0), count(*)), 4) as late_payment_rate,
    round(avg(case when days_late > 0 then days_late end), 1) as avg_days_late_when_late,
    sum(case when payment_shortfall > 0 then payment_shortfall else 0 end) as total_shortfall
from installments
group by application_id
