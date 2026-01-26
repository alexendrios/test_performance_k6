#!/bin/bash

# Uso:
# ./helpers/run-test-with-status.sh <test-name> <env> <results-dir>

TEST_NAME=$1
ENVIRONMENT=$2
RESULTS_DIR=$3

if [ -z "$TEST_NAME" ] || [ -z "$ENVIRONMENT" ] || [ -z "$RESULTS_DIR" ]; then
  echo "Uso: run-test-with-status.sh <test-name> <env> <results-dir>"
  exit 2
fi

STATUS_FILE="$RESULTS_DIR/status.csv"
SUMMARY_FILE="$RESULTS_DIR/$TEST_NAME-summary.json"

# Cria o status.csv se não existir
if [ ! -f "$STATUS_FILE" ]; then
  echo "test,status,type" > "$STATUS_FILE"
fi

echo "▶ Executando teste: $TEST_NAME"

k6 run \
  --env ENV="$ENVIRONMENT" \
  --summary-export="$SUMMARY_FILE" \
  tests/$TEST_NAME.js

EXIT_CODE=$?

# Classificação do resultado
if [ $EXIT_CODE -eq 0 ]; then
  echo "$TEST_NAME,OK,success" >> "$STATUS_FILE"
  echo "✔ $TEST_NAME OK"
else
  if [ -s "$SUMMARY_FILE" ]; then
    echo "$TEST_NAME,FAIL,threshold" >> "$STATUS_FILE"
    echo "❌ $TEST_NAME falhou por THRESHOLD"
  else
    echo "$TEST_NAME,ERROR,technical" >> "$STATUS_FILE"
    echo "💥 $TEST_NAME falhou por ERRO TÉCNICO"
  fi
fi

exit 0
