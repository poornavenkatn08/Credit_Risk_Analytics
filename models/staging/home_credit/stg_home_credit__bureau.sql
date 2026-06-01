with source as (
    select * from {{ source('home_credit_raw', 'bureau') }}
),

cleaned as (
    select
        cast(SK_ID_BUREAU as int64)                       as bureau_credit_id,
        cast(SK_ID_CURR   as int64)                       as application_id,
        CREDIT_ACTIVE                                     as credit_status,   -- Active/Closed/Sold/Bad debt
        CREDIT_TYPE                                       as credit_type,
        safe_cast(DAYS_CREDIT as int64)                   as days_since_credit_opened,
        safe_cast(CREDIT_DAY_OVERDUE as int64)            as days_overdue,
        safe_cast(AMT_CREDIT_SUM         as numeric)      as credit_sum,
        safe_cast(AMT_CREDIT_SUM_DEBT    as numeric)      as credit_debt,
        safe_cast(AMT_CREDIT_SUM_OVERDUE as numeric)      as credit_overdue
    from source
)

select * from cleaned
