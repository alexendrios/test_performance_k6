#!/bin/bash
set +e  # nunca quebrar pipeline

TEST_NAME="$1"
ENVIRONMENT="$2"
RESULTS_DIR="$3"

if [ -z "$TEST_NAME" ] || [ -z "$ENVIRONMENT" ] || [ -z "$RESULTS_DIR" ]; then
  echo "Uso: run-test-with-status.sh <test-name> <env> <results-dir>"
  exit 2
fi

SCRIPT="tests/${TEST_NAME}.js"

if [ ! -f "$SCRIPT" ]; then
  echo "❌ Script não encontrado: $SCRIPT"
  exit 3
fi

STATUS_FILE="$RESULTS_DIR/status.csv"
RAW_SUMMARY="$RESULTS_DIR/${TEST_NAME}-summary.json"
METRICS_FILE="$RESULTS_DIR/${TEST_NAME}-metrics.json"

# Inicializa status.csv
if [ ! -f "$STATUS_FILE" ]; then
  echo "test,status,type" > "$STATUS_FILE"
fi

echo "🚀 Running test: $ENVIRONMENT ($TEST_NAME)"

# ==============================
# Executa k6 (pipeline nunca quebra)
# ==============================
k6 run \
  --env ENV="$ENVIRONMENT" \
  --summary-export="$RAW_SUMMARY" \
  "$SCRIPT"

EXIT_CODE=$?

# ==============================
# Normaliza métricas de forma defensiva
# ==============================
if [ -f "$RAW_SUMMARY" ]; then
  jq '
  {
    http_req_duration_p95: (
      if (.metrics.http_req_duration["p(95)"] | type=="number") then
        .metrics.http_req_duration["p(95)"]
      else
        0
      end
    ),
    http_req_failed_rate: (
      if (.metrics.http_req_failed.value | type=="number") then
        .metrics.http_req_failed.value
      else
        0
      end
    ),
    checks_pass_rate: (
      if (.metrics.checks and (.metrics.checks.passes + .metrics.checks.fails) > 0) then
        ((.metrics.checks.passes * 100) / (.metrics.checks.passes + .metrics.checks.fails))
      else
        0
      end
    ),
    vus_max: (
      if (.metrics.vus_max.value | type=="number") then
        .metrics.vus_max.value
      else
        0
      end
    )
  }
  ' "$RAW_SUMMARY" > "$METRICS_FILE"
else
  echo '{"http_req_duration_p95":0,"checks_pass_rate":0,"http_req_failed_rate":0,"vus_max":0}' > "$METRICS_FILE"
fi

# ==============================
# Validação defensiva
# ==============================
if [ ! -s "$METRICS_FILE" ]; then
  echo "⚠ Falha ao gerar métricas"
  echo "$TEST_NAME,FAIL,technical" >> "$STATUS_FILE"
  exit 0
fi

# ==============================
# Determina Status real do teste
# ==============================
if [ "$EXIT_CODE" -eq 0 ]; then
  STATUS="OK"
  TYPE="success"
  echo "✔ $TEST_NAME OK"
else
  STATUS="FAIL"
  TYPE="threshold"
  echo "❌ $TEST_NAME FAIL (registrado, pipeline continua)"
fi

# ==============================
# Salva status no CSV
# ==============================
echo "$TEST_NAME,$STATUS,$TYPE" >> "$STATUS_FILE"

exit 0
