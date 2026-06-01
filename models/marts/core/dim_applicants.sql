-- Grain: one row per application_id. Descriptive applicant attributes only;
-- all measures and the default outcome live in fct_applications. Splitting the
-- descriptive context (dimension) from the measures (fact) even though they
-- share a grain is the standard Kimball separation.
with apps as (
    select * from {{ ref('stg_home_credit__applications') }}
)

select
    application_id,
    gender,
    education,
    family_status,
    housing_type,
    income_type,
    occupation,
    owns_car,
    owns_realty,
    children_count,
    age_years,
    -- banded attributes for clean dashboard slicing
    case
        when age_years < 25 then 'Under 25'
        when age_years < 35 then '25-34'
        when age_years < 45 then '35-44'
        when age_years < 55 then '45-54'
        when age_years < 65 then '55-64'
        else '65+'
    end as age_band,
    employment_years,
    case
        when income_total < 100000 then 'Low (<100k)'
        when income_total < 200000 then 'Mid (100-200k)'
        when income_total < 350000 then 'High (200-350k)'
        else 'Very High (350k+)'
    end as income_band
from apps
