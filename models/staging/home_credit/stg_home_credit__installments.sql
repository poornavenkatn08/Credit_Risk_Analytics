with source as (
    select * from {{ source('home_credit_raw', 'installments_payments') }}
),

cleaned as (
    select
        cast(SK_ID_PREV as int64)                         as prev_loan_id,
        cast(SK_ID_CURR as int64)                         as application_id,
        safe_cast(NUM_INSTALMENT_NUMBER  as int64)        as installment_number,
        safe_cast(NUM_INSTALMENT_VERSION as int64)        as installment_version,
        safe_cast(DAYS_INSTALMENT    as int64)            as days_due,        -- when due (neg offset)
        safe_cast(DAYS_ENTRY_PAYMENT as int64)            as days_paid,       -- when actually paid
        safe_cast(AMT_INSTALMENT as numeric)              as amount_due,
        safe_cast(AMT_PAYMENT    as numeric)              as amount_paid,
        -- positive = paid after due date (later in time = less negative offset)
        safe_cast(DAYS_ENTRY_PAYMENT as int64) - safe_cast(DAYS_INSTALMENT as int64) as days_late,
        -- positive = underpaid
        safe_cast(AMT_INSTALMENT as numeric) - safe_cast(AMT_PAYMENT as numeric)     as payment_shortfall
    from source
)

select * from cleaned
