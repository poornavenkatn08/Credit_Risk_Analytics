with source as (
    select * from {{ source('home_credit_raw', 'application_train') }}
),

cleaned as (
    select
        cast(SK_ID_CURR as int64)                              as application_id,
        cast(TARGET as int64)                                  as is_default,      -- 1 = payment difficulties
        NAME_CONTRACT_TYPE                                     as contract_type,
        -- a handful of rows carry gender 'XNA'
        case when CODE_GENDER = 'XNA' then 'Unknown' else CODE_GENDER end as gender,
        (upper(cast(FLAG_OWN_CAR    as string)) in ('Y', 'TRUE')) as owns_car,
        (upper(cast(FLAG_OWN_REALTY as string)) in ('Y', 'TRUE')) as owns_realty,
        cast(CNT_CHILDREN as int64)                            as children_count,
        safe_cast(AMT_INCOME_TOTAL as numeric)                 as income_total,
        safe_cast(AMT_CREDIT       as numeric)                 as credit_amount,
        safe_cast(AMT_ANNUITY      as numeric)                 as annuity_amount,
        safe_cast(AMT_GOODS_PRICE  as numeric)                 as goods_price,
        NAME_INCOME_TYPE                                       as income_type,
        NAME_EDUCATION_TYPE                                    as education,
        NAME_FAMILY_STATUS                                     as family_status,
        NAME_HOUSING_TYPE                                      as housing_type,
        OCCUPATION_TYPE                                        as occupation,
        -- DAYS_BIRTH is negative days-from-application; convert to age in years
        cast(floor(-1 * safe_cast(DAYS_BIRTH as numeric) / 365.25) as int64) as age_years,
        -- DAYS_EMPLOYED uses sentinel 365243 (~18% of rows) for "not employed"
        -- (pensioners/unemployed). Treat it as NULL rather than 1000+ years.
        case
            when safe_cast(DAYS_EMPLOYED as int64) = 365243 then null
            else cast(floor(-1 * safe_cast(DAYS_EMPLOYED as numeric) / 365.25) as int64)
        end                                                    as employment_years,
        safe_cast(REGION_RATING_CLIENT as int64)               as region_rating,
        safe_cast(EXT_SOURCE_2 as numeric)                     as ext_score_2,
        safe_cast(EXT_SOURCE_3 as numeric)                     as ext_score_3
    from source
)

select * from cleaned
