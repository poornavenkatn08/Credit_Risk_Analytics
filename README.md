# Home Credit — Credit Risk Analytics Engineering Pipeline

An end-to-end **analytics engineering** project in the credit-risk domain. Raw
lending data from ~307K loan applications is transformed into a governed, tested
dimensional warehouse using **dbt** on **Google BigQuery**, then surfaced as an
interactive **Tableau** dashboard that answers three portfolio-risk questions.

**🔗 [Live Tableau dashboard](https://public.tableau.com/app/profile/poorna.venkat.neelakantam/viz/HomeCredit-Risk/HomeCredit-PortfolioRisk)**

---

## TL;DR

| | |
|---|---|
| **Domain** | Consumer credit / lending risk |
| **Stack** | dbt · Google BigQuery · SQL · Tableau Public |
| **Scale** | 307,511 applications · 13.6M payment records · external bureau history |
| **Model** | Fact constellation (3 facts, 1 conformed dimension) |
| **Quality** | ~25 automated dbt tests run on every build |
| **Headline finding** | Default rate nearly **doubles** (6.7% → 12.7%) as an applicant's late-payment history worsens |

---

## What this demonstrates

- **Modern data stack** — dbt transformations landing in a cloud data warehouse, served to a BI tool.
- **Dimensional modeling** — a fact-constellation (galaxy) schema: three fact tables at three grains sharing one conformed dimension.
- **Data quality as code** — uniqueness, not-null, referential-integrity, accepted-values and accepted-range tests, executed automatically with every `dbt build`.
- **Real-world data wrangling** — handling an anonymized-date dataset, sentinel-value cleaning, and BigQuery type-inference edge cases.
- **Insight → recommendation** — the pipeline doesn't just move data; it produces business findings and the decisions they support (see [`FINDINGS.md`](FINDINGS.md)).

---

## Architecture

```
 Kaggle CSVs ─► BigQuery (raw) ─► dbt ──────────────────────────────► Tableau
                                   │
              staging (views) ─► intermediate (views) ─► marts (tables)
              rename / cast /     applicant-level          dim + 3 facts
              sentinel fixes      credit-history rollups   + 3 presentation marts
```

**Layered design:** `staging → intermediate → marts (core + presentation)`. Staging
and intermediate materialize as cheap views; marts materialize as tables for fast
BI queries.

---

## Data model

A **fact constellation** — three facts at different grains, all sharing the
conformed `dim_applicants` dimension. Full ERD and rationale in
[`docs/data_model.md`](docs/data_model.md).

| Table | Type | Grain |
|---|---|---|
| `fct_applications` | fact | one loan application (+ default flag) |
| `fct_bureau_credits` | fact | one external credit record |
| `fct_installments` | fact | one installment payment (prior loans) |
| `dim_applicants` | dimension (conformed) | one applicant |

**Presentation marts** (BI-facing): `mart_default_by_segment`,
`mart_portfolio_exposure`, `mart_credit_history_risk`.

### Two modeling decisions worth calling out
- **No date dimension — on purpose.** Home Credit anonymizes every date as an
  integer day-offset relative to each application; there are no calendar dates,
  so a conformed `dim_dates` is impossible. Relative-time signals are kept as
  attributes on the facts instead.
- **Referential scoping.** The raw bureau and installment files reference some
  applicants outside the modeled population, so those facts are inner-joined to
  the modeled applicants — keeping every foreign key valid and the
  `relationships` tests green.

---

## Key findings

Computed by the pipeline on the full dataset. Detail and business recommendations
in [`FINDINGS.md`](FINDINGS.md).

1. **Behavior beats balance-sheet.** Default rate rises monotonically with prior
   late-payment history (6.72% → 7.96% → 9.93% → 12.70%), while average debt and
   credit-line count stay flat across those bands. Repayment *discipline*, not
   borrowing *volume*, is the signal.
2. **Education outweighs income.** The lowest-risk segment (high-income, higher
   education) defaults at ~5%; the highest (mid-income, lower-secondary) at ~12.6%.
3. **Product concentration risk.** Revolving loans default far less than cash
   loans in every income band, yet the portfolio's exposure is overwhelmingly
   concentrated in the riskier cash-loan product.

---

## Business questions this answers
- **Which applicants are most likely to default — and why?** → past late-payment behavior is the strongest signal (default rate climbs 6.7% → 12.7%), stronger than debt size or number of credit lines.
- **Which borrower segments carry the most risk?** → lower-education, lower-income segments default at up to ~12.6% vs ~5% for high-income/higher-education.
- **Where is our lending exposure concentrated, and at what risk?** → overwhelmingly in cash loans, which default more than revolving loans in every income band.

## Recommendations
1. **Make prior-loan payment behavior a primary underwriting input.** The 6.7% → 12.7% spread is large enough to drive tiered approval or risk-based pricing; treat the >25%-late segment (~1.9x average default) as manual-review rather than auto-approve.
2. **Do not lean on debt size or credit-line count as risk proxies** — they're flat across risk bands here; behavioral and affordability signals carry the information.
3. **Reassess product concentration** — exposure sits disproportionately in the higher-default cash-loan product; price that risk explicitly or grow the lower-risk revolving book.
4. **Use demographic gradients for monitoring, not decisioning** — education/income gradients are real but acting on them directly raises fair-lending concerns; lean on behavior and affordability instead.

## Repository structure

```
.
├── models/
│   ├── staging/home_credit/   # 3 stg_ models (rename, cast, sentinel fixes) + tests
│   ├── intermediate/          # 2 int_ models (bureau + installment rollups)
│   └── marts/
│       ├── core/              # dim_applicants + 3 fct_ tables (the constellation)
│       └── presentation/      # 3 BI-ready marts
├── analyses/
│   └── kpi_definitions.sql    # canonical KPI SQL (default rate, exposure, etc.)
├── docs/
│   ├── data_model.md          # ERD + modeling rationale
│   └── metric_definitions.md  # KPI catalog
├── tableau/
│   ├── export_marts_for_tableau.sh  # marts -> CSV for Tableau Public
│   └── DASHBOARD_GUIDE.md           # how the dashboard was built
├── load_to_bigquery.sh        # raw CSVs -> BigQuery
├── dbt_project.yml
├── packages.yml
├── profiles.yml.example       # connection template (real profile is git-ignored)
├── requirements.txt
├── FINDINGS.md                # results + business recommendations
└── RUNBOOK.md                 # full step-by-step setup guide
```

---

## Quickstart

> Full, detailed walkthrough (incl. Google Cloud + Kaggle setup) is in
> [`RUNBOOK.md`](RUNBOOK.md).

```bash
# 1. environment
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt

# 2. load raw data into BigQuery (after downloading the Kaggle CSVs into ./data)
bash load_to_bigquery.sh         # edit PROJECT inside it first

# 3. configure the connection
cp profiles.yml.example ~/.dbt/profiles.yml   # then set your GCP project

# 4. build + test the warehouse
dbt deps
dbt build                        # runs every model AND every test
dbt docs generate && dbt docs serve   # interactive lineage graph

# 5. export marts for Tableau
bash tableau/export_marts_for_tableau.sh
```

---

## Tech stack

| Layer | Tool |
|---|---|
| Transformation | dbt Core (`dbt-bigquery`) |
| Warehouse | Google BigQuery |
| Language | SQL |
| Visualization | Tableau Public |
| Testing/docs | dbt tests, dbt docs, `dbt_utils` |

---

## Dataset & disclaimer

Data: [Home Credit Default Risk](https://www.kaggle.com/competitions/home-credit-default-risk/data)
(Kaggle competition, public). A free Kaggle account is required to download.

This is a **portfolio project on public competition data**. The figures describe
what the analysis demonstrates on this dataset; they are **not** a validated,
regulatory-grade credit-risk model and carry no production or regulatory standing.

---

## Author

**Poorna Venkat Neelakantam** — Data & Analytics
[GitHub](https://github.com/poornavenkatn08) ·
[Tableau Public](https://public.tableau.com/app/profile/poorna.venkat.neelakantam)
