#!/usr/bin/env bash
# Exports the three presentation marts from BigQuery to local CSVs for Tableau.
# Run from the project root after a successful `dbt build`.
set -euo pipefail

PROJECT="home-credit-risk-498020"
MARTS_DATASET="dbt_dev_marts"        # change if `bq ls` shows a different name
OUT="tableau/data"
mkdir -p "$OUT"

for mart in mart_default_by_segment mart_portfolio_exposure mart_credit_history_risk; do
  echo "Exporting ${mart} ..."
  bq query --use_legacy_sql=false --format=csv --max_rows=100000 \
    "SELECT * FROM \`${PROJECT}.${MARTS_DATASET}.${mart}\`" > "${OUT}/${mart}.csv"
done

echo "Done. CSVs are in ${OUT}/"
ls -la "$OUT"