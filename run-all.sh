#!/bin/bash

# ==============================
# Configurações
# ==============================
ENV=${ENV:-dev}
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
RESULTS_DIR="results/$ENV/$TIMESTAMP"

mkdir -p "$RESULTS_DIR"

TESTS=(
  smoke
  sanity-load
  load
  stress
  spike
  soak
  capacity
  peak-capacity
  breakpoint
  recovery
  throughput-curve
)

echo "======================================"
echo "🚀 Iniciando bateria de testes k6"
echo "🌎 Ambiente: $ENV"
echo "🕒 Execução: $TIMESTAMP"
echo "📁 Resultados em: $RESULTS_DIR"
echo "======================================"
echo ""

# ==============================
# Execução da bateria
# ==============================
for TEST in "${TESTS[@]}"; do
  echo "==============================="
  echo "▶ Iniciando teste: $TEST"
  echo "==============================="

  ./helpers/run-test-with-status.sh "$TEST" "$ENV" "$RESULTS_DIR"

  echo ""
  sleep 10
done

# ==============================
# Resumo
# ==============================
STATUS_FILE="$RESULTS_DIR/status.csv"

echo "==============================="
echo "📊 Resumo da bateria"
echo "==============================="

if [ -f "$STATUS_FILE" ]; then
  FAILED=$(grep -E "FAIL|ERROR" "$STATUS_FILE" | wc -l | tr -d ' ')
else
  FAILED=0
fi

if [ "$FAILED" -gt 0 ]; then
  echo "❌ Foram detectadas falhas:"
  cat "$STATUS_FILE" | sed 1d | grep -E "FAIL|ERROR"
else
  echo "✅ Todos os testes passaram com sucesso"
fi

echo ""

# ==============================
# Dashboard
# ==============================
echo "🧾 Gerando dashboard HTML..."
./helpers/generate-index.sh

echo "🌐 Abrindo dashboard..."
start reports/index.html

# ==============================
# Exit code para CI
# ==============================
if [ "$FAILED" -gt 0 ]; then
  echo "🚨 Bateria finalizada com falhas"
  exit 1
fi

echo "🎉 Bateria finalizada com sucesso"
exit 0
