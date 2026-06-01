# Dimensional Model

A **fact constellation** (galaxy schema): three fact tables at different grains,
all sharing one conformed dimension, `dim_applicants`.

## Schema (text ERD)

                         +------------------+
                         |  dim_applicants  |   grain: one applicant/application
                         +------------------+
                          /        |        \
                         /         |         \
        +------------------+ +--------------+ +--------------------+
        | fct_applications | | fct_bureau_  | | fct_installments   |
        | grain: 1 loan    | | credits      | | grain: 1 payment   |
        | + default flag   | | grain: 1 ext | | record (prior loan)|
        +------------------+ | credit       | +--------------------+
                             +--------------+

## Layers (build order)
raw -> staging (views) -> intermediate (views) -> marts (tables)
       rename/cast/         applicant-level         dim + 3 facts
       sentinel fixes       credit-history rollups  + presentation marts

## Why a fact constellation (not one star)?
Three different things happen at three different grains: a loan is decided (one
row per application), an external credit exists (one row per bureau record), and
a payment is made (one row per installment). Forcing them into one table would
mangle the grain. They share the applicant, so `dim_applicants` is the conformed
dimension that ties the galaxy together.

## Why there is NO date dimension
Home Credit anonymizes every date as an integer **day offset relative to each
application** (negative = in the past). There are no absolute calendar dates, so
a conformed calendar `dim_dates` is impossible. Relative-time information is kept
as attributes on the facts (e.g. `days_since_credit_opened`, `days_late`).

## Key cleaning / modeling decisions (the senior signals)
- **DAYS_EMPLOYED sentinel:** ~18% of rows store `365243` to mean "not employed"
  (pensioners/unemployed). Left raw it implies ~1000 years of tenure, so it is
  converted to NULL in staging.
- **Negative day offsets** are converted to positive ages/tenures in years.
- **Gender 'XNA'** (a few rows) is mapped to 'Unknown'.
- **Referential scoping:** the raw bureau and installment files reference some
  applicants from the held-out test set. Both facts are inner-joined to the
  modeled applicants so every FK resolves and `relationships` tests pass.
- **Installments grain:** the source has no reliable single natural key, so the
  row is surrogate-keyed and uniqueness is deliberately not asserted.
- **Class imbalance:** ~8% of applications default; segment comparisons use rates.
