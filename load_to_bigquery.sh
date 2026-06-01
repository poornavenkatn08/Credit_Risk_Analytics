#!/usr/bin/env bash

set -euo pipefail

PROJECT="home-credit-risk-498020"   
DATASET="home_credit_raw"
DATA_DIR="${1:-./data}"

bq --location=US mk -f --dataset "${PROJECT}:${DATASET}" || true

declare -A FILES=(
  [application_train]="application_train.csv"
  [bureau]="bureau.csv"
  [installments_payments]="installments_payments.csv"
)

for table in "${!FILES[@]}"; do
  echo "Loading ${table} ..."
  bq --location=US load \
    --source_format=CSV --autodetect --skip_leading_rows=1 --replace \
    --max_bad_records=50 \
    "${PROJECT}:${DATASET}.${table}" "${DATA_DIR}/${FILES[$table]}"
done

echo "Done. Raw tables are in ${PROJECT}.${DATASET}"
echo "Note: installments_payments is ~13.6M rows; the first build will take a few minutes."
