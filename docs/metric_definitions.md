# Metric Definitions (Risk KPI Catalog)

Canonical risk metrics for the Home Credit warehouse, defined once in the
semantic layer (`semantic_models/`) and consumed by every dashboard.

| Metric | Definition | Grain | Notes |
|---|---|---|---|
| Total Applications | COUNT(application_id) | Application | The modeled loan population |
| Default Rate | defaults / applications | Application | "Default" = TARGET 1 = payment difficulties. Dataset rate ~8% |
| Total Exposure | SUM(credit_amount) | Application | Money at risk |
| Avg Credit-to-Income | AVG(credit_amount / income_total) | Application | A core underwriting ratio; **AVG, never SUM** |
| Late Payment Rate | late installments / total installments | Applicant | Historical repayment discipline (from prior loans) |
| Delinquency Bucket | days past due banded (1-30/31-60/61-90/90+) | Installment | Standard DPD buckets |

## Modeling rules that protect these numbers
- The dataset is **imbalanced** (~8% default rate). Always report default *rate*,
  not raw counts, when comparing segments of different sizes.
- `is_default` is summed to count defaults but the headline metric is a **ratio**.
- Ratios like credit-to-income are **averaged, never summed**.
- Bureau and installment facts are **scoped to modeled applicants**, so totals
  reflect the modeled population, not the full raw files.

## A note on intended use
This is a portfolio exercise on a public Kaggle competition dataset. The figures
describe **what the analysis demonstrates** on this data. They are not a
validated credit-risk model and carry no regulatory standing.
