-- Grain: one row per external credit (bureau_credit_id). Scoped to applicants we
-- model, so referential integrity to dim_applicants holds (the raw bureau file
-- also references applicants from the held-out test set).
with bureau as (
    select * from {{ ref('stg_home_credit__bureau') }}
),

modeled_applicants as (
    select application_id from {{ ref('fct_applications') }}
)

select
    b.bureau_credit_id,
    b.application_id,                     -- FK -> dim_applicants
    b.credit_status,                      -- degenerate dimension
    b.credit_type,                        -- degenerate dimension
    b.days_since_credit_opened,
    b.credit_sum,
    b.credit_debt,
    b.credit_overdue
from bureau b
inner join modeled_applicants m using (application_id)
