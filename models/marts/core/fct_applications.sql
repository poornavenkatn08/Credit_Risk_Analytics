-- Grain: one row per application_id. The central risk fact: loan economics plus
-- the default outcome. FK application_id -> dim_applicants.
with apps as (
    select * from {{ ref('stg_home_credit__applications') }}
)

select
    application_id,                       -- FK -> dim_applicants
    is_default,                           -- measure: 1 = payment difficulties
    contract_type,                        -- degenerate dimension
    region_rating,
    -- loan economics
    credit_amount,
    income_total,
    annuity_amount,
    goods_price,
    -- risk ratios (the bread and butter of credit underwriting)
    round(safe_divide(credit_amount,  nullif(income_total, 0)), 3) as credit_to_income_ratio,
    round(safe_divide(annuity_amount, nullif(income_total, 0)), 4) as annuity_to_income_ratio,
    -- external normalized risk scores (higher = lower risk in this dataset)
    ext_score_2,
    ext_score_3
from apps
