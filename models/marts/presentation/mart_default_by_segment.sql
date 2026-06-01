-- Default rate by applicant segment -- the core question underwriting asks:
-- which borrower profiles carry more risk? Built from fct_applications + dim.
with apps as (
    select application_id, is_default from {{ ref('fct_applications') }}
),

applicants as (
    select application_id, age_band, education, family_status, income_band
    from {{ ref('dim_applicants') }}
)

select
    a.income_band,
    a.education,
    count(*)                                          as applications,
    sum(ap.is_default)                                as defaults,
    round(safe_divide(sum(ap.is_default), count(*)) * 100, 2) as default_rate_pct
from apps ap
inner join applicants a using (application_id)
group by a.income_band, a.education
order by default_rate_pct desc
