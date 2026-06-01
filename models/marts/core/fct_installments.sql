-- Grain: one row per installment payment record on prior Home Credit loans.
-- No reliable single natural key exists in the source, so we surrogate-key the
-- row and do NOT assert uniqueness (documented in docs/data_model.md). Scoped to
-- modeled applicants for referential integrity.
with installments as (
    select * from {{ ref('stg_home_credit__installments') }}
),

modeled_applicants as (
    select application_id from {{ ref('fct_applications') }}
)

select
    {{ dbt_utils.generate_surrogate_key([
        'i.prev_loan_id', 'i.installment_number', 'i.installment_version',
        'i.days_due', 'i.days_paid', 'i.amount_paid'
    ]) }}                                 as installment_key,
    i.application_id,                     -- FK -> dim_applicants
    i.prev_loan_id,
    i.installment_number,
    i.amount_due,
    i.amount_paid,
    i.payment_shortfall,
    i.days_late,
    (i.days_late > 0)                     as is_late,
    case
        when i.days_late is null   then 'No payment recorded'
        when i.days_late <= 0      then 'On time / Early'
        when i.days_late <= 30     then '1-30 DPD'
        when i.days_late <= 60     then '31-60 DPD'
        when i.days_late <= 90     then '61-90 DPD'
        else '90+ DPD'
    end                                   as delinquency_bucket
from installments i
inner join modeled_applicants m using (application_id)
