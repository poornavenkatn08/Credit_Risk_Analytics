# Findings — Home Credit Risk Analytics

Results produced by the pipeline on the full Home Credit dataset (307,511 loan
applications). All figures below are computed by the dbt models in this project
and were validated against the source data.

> Scope note: this is a portfolio analysis on a public Kaggle competition
> dataset. Figures describe what the analysis demonstrates on this data; they are
> not a validated, regulatory-grade credit-risk model.

---

## Headline numbers

- **307,511** loan applications analyzed.
- **8.07%** overall default rate (matches the dataset's published benchmark — a
  check that the modeling and cleaning introduced no distortion).
- The data is **imbalanced** (~1 in 12 defaults), so every comparison below uses
  default *rate*, not raw counts.

---

## Finding 1 — Past repayment behavior is the strongest predictor of default

Default rate rises monotonically with an applicant's history of late payments on
prior loans:

| Late-payment history | Applicants | Default rate |
|---|---|---|
| No late payments | 152,512 | 6.72% |
| Up to 10% late | 77,129 | 7.96% |
| 10–25% late | 52,245 | 9.93% |
| Over 25% late | 25,625 | 12.70% |

An applicant late on >25% of past payments defaults at **nearly 2× the rate** of
one who was never late (12.70% vs 6.72%), a clean stair-step with no reversals.

**The subtle part:** average external debt (~515K–575K) and prior-credit count
(~4.4–5.3) are essentially flat across all four bands. So risk is not driven by
*how much* an applicant has borrowed or *how many* credit lines they hold — it is
driven by their *behavioral discipline* in repaying. Behavior beats balance-sheet
size.

**Caveat:** the "No late payments" band (the largest group) blends genuinely
reliable payers with thin-file applicants who simply have no recorded history. A
natural follow-up would separate those two populations.

---

## Finding 2 — Education is a stronger demographic signal than income

Holding income roughly constant, default rate falls steadily as education rises;
income matters too, but is the weaker of the two signals.

- Highest-risk cell: **Mid income + Lower secondary education — 12.57%**
- Lowest-risk cell: **High income + Higher education — 5.10%**
- Higher-education applicants default at roughly **half** the rate of
  Lower-secondary applicants at comparable income.

Within Higher education, income still moves the needle (5.96% at Low income →
5.10% at High income), confirming income as a secondary, consistent factor.

---

## Finding 3 — Product mix is a concentration risk

Revolving loans default markedly less than cash loans in every income band:

| Income band | Cash loan default | Revolving loan default |
|---|---|---|
| Low (<100k) | 8.40% | 6.76% |
| Mid (100–200k) | 8.83% | 5.83% |
| High (200–350k) | 7.68% | 3.80% |
| Very High (350k+) | 6.29% | 2.38% |

Yet exposure is overwhelmingly concentrated in the **riskier** product:
cash loans hold roughly **174B** in total exposure versus only **~9.5B** for
revolving loans. The portfolio's money sits disproportionately in the
higher-default product.

Leverage tracks risk in the expected direction: average credit-to-income is
highest in the low-income cash-loan segment (5.39) and lowest in the safest
revolving segments (1.6–1.8).

---

## Business recommendations

These follow directly from the findings above (illustrative of how the analysis
would inform decisions, not deployable policy).

1. **Make prior-loan payment behavior a primary underwriting input.** The
   6.72% → 12.70% spread across late-payment bands is large enough to drive
   tiered approval thresholds or risk-based pricing. Treat the >25%-late segment
   (≈1.9× the portfolio average default rate) as manual-review or higher-priced
   rather than auto-approve.

2. **Do not lean on debt size or credit-line count as risk proxies.** They are
   flat across risk bands in this data; weighting them would add little and could
   mislead. Favor behavioral and affordability signals instead.

3. **Reassess product concentration.** The portfolio is heavily weighted toward
   cash loans, the higher-default product. Either price that risk more
   explicitly or evaluate growing the lower-risk revolving book.

4. **Use demographic gradients for monitoring, not decisioning.** Education and
   income gradients are real, but acting on them directly raises fair-lending
   concerns. Lean on behavior (payment history) and affordability (leverage
   ratios); treat the segment view as portfolio monitoring.

---

## How these were produced

| Finding | Source mart | Query |
|---|---|---|
| Overall default rate | `fct_applications` | `AVG(is_default)` |
| Finding 1 | `mart_credit_history_risk` | grouped by late-payment band |
| Finding 2 | `mart_default_by_segment` | income band × education |
| Finding 3 | `mart_portfolio_exposure` | contract type × income band |
