#!/usr/bin/env bash
set -Eeuo pipefail

########################################
# LOCALE (evita erro com decimal)
########################################
export LC_ALL=C
export LANG=C

########################################
# CONFIGURAÇÃO GERAL
########################################
ENV="${ENV:-dev}"
TIMESTAMP="$(date '+%Y%m%d_%H%M%S')"

ROOT_DIR="$(pwd)"
BASE_DIR="$ROOT_DIR/results/$ENV"
RESULTS_DIR="$BASE_DIR/$TIMESTAMP"
BASELINE_DIR="$BASE_DIR/latest-metrics"
EXPORT_DIR="$RESULTS_DIR/exports"

TESTS=(smoke sanity-load load)

EXEC_SUMMARY_JSON="$EXPORT_DIR/summary.json"
EXEC_SUMMARY_CSV="$EXPORT_DIR/summary.csv"

########################################
# PREPARAÇÃO DE DIRETÓRIOS
########################################
mkdir -p "$RESULTS_DIR" "$BASELINE_DIR" "$EXPORT_DIR"

########################################
# HEADER
########################################
echo "======================================"
echo "🚀 Iniciando bateria de testes k6"
echo "🌎 Ambiente:   $ENV"
echo "🕒 Execução:   $TIMESTAMP"
echo "📁 Resultados: $RESULTS_DIR"
echo "======================================"
echo ""

########################################
# FUNÇÕES AUXILIARES
########################################
to_int() {
  echo "$1" | sed 's/,/./' | awk '{printf "%d", ($1 * 100 + 0.5)}'
}

safe_metric() {
  local key="$1"
  local file="$2"

  [ -f "$file" ] || { echo "0"; return; }

  jq -r --arg k "$key" '.[$k] // 0' "$file" 2>/dev/null || echo "0"
}

########################################
# INICIALIZA SUMMARY
########################################
echo "test,p95,baseline_p95,delta_pct,checks,score,trend,risk,status" \
  > "$EXEC_SUMMARY_CSV"

echo "[" > "$EXEC_SUMMARY_JSON"

TOTAL_SCORE=0
TEST_COUNT=0
HAS_HIGH_RISK=0

########################################
# EXECUÇÃO DOS TESTES
########################################
for TEST in "${TESTS[@]}"; do
  echo "▶ Executando teste: $TEST"

  ./helpers/run-test-with-status.sh "$TEST" "$ENV" "$RESULTS_DIR"

  METRICS_FILE="$RESULTS_DIR/${TEST}-metrics.json"
  REPORT_FILE="$EXPORT_DIR/${TEST}-report.html"
  BASELINE_FILE="$BASELINE_DIR/${TEST}-metrics.json"

  ####################################
  # GERA REPORT DO TESTE
  ####################################
  echo "🧾 Gerando report HTML: $TEST"

  if [ -f "$METRICS_FILE" ]; then
    ./helpers/generate-test-report.sh \
     "$TEST" \
     "$RESULTS_DIR" \
     "$EXPORT_DIR"


    if [ -f "$REPORT_FILE" ]; then
      echo "✅ Report criado: $REPORT_FILE"
    else
      echo "❌ ERRO: Report NÃO foi criado: $REPORT_FILE"
    fi
  else
    echo "⚠️ Metrics inexistente, report ignorado: $METRICS_FILE"
  fi

  ####################################
  # GARANTE BASELINE
  ####################################
  [ -f "$BASELINE_FILE" ] || echo '{}' > "$BASELINE_FILE"

  ####################################
  # MÉTRICAS
  ####################################
  P95="$(safe_metric http_req_duration_p95 "$METRICS_FILE")"
  CHECKS="$(safe_metric checks_pass_rate "$METRICS_FILE")"
  BASE_P95="$(safe_metric http_req_duration_p95 "$BASELINE_FILE")"

  P95_INT="$(to_int "$P95")"
  BASE_P95_INT="$(to_int "$BASE_P95")"
  CHECKS_INT="$(to_int "$CHECKS")"

  ####################################
  # DELTA %
  ####################################
  if [ "$BASE_P95_INT" -eq 0 ]; then
    DELTA_INT=0
  else
    DELTA_INT=$(( (P95_INT - BASE_P95_INT) * 10000 / BASE_P95_INT ))
  fi

  DELTA_PCT="$(awk "BEGIN {printf \"%.2f\", $DELTA_INT/100}")"

  ####################################
  # TREND
  ####################################
  if   [ "$DELTA_INT" -lt -500 ]; then TREND="🟢 Melhorou"
  elif [ "$DELTA_INT" -gt  500 ]; then TREND="🔴 Regressão"
  else                                TREND="🟡 Estável"
  fi

  ####################################
  # RISCO
  ####################################
  if [ "$DELTA_INT" -gt 1500 ]; then
    RISK="HIGH"
    HAS_HIGH_RISK=1
    echo "⚠️ ALERTA: Risco HIGH em $TEST"
  elif [ "$DELTA_INT" -gt 500 ]; then
    RISK="MEDIUM"
  else
    RISK="LOW"
  fi

  ####################################
  # SCORE
  ####################################
  SCORE=100
  [ "$P95_INT"    -gt 50000 ] && SCORE=$(( SCORE - (P95_INT - 50000)/5 ))
  [ "$CHECKS_INT" -lt 9900  ] && SCORE=$(( SCORE - (9900 - CHECKS_INT)*2 ))

  (( SCORE < 0 ))   && SCORE=0
  (( SCORE > 100 )) && SCORE=100

  TOTAL_SCORE=$(( TOTAL_SCORE + SCORE ))
  TEST_COUNT=$(( TEST_COUNT + 1 ))

  ####################################
  # STATUS
  ####################################
  STATUS="OK"
  [ "$P95_INT" -gt 100000 ] && STATUS="FAIL"

  ####################################
  # CSV
  ####################################
  printf "%s,%.2f,%.2f,%.2f,%.2f,%d,%s,%s,%s\n" \
    "$TEST" "$P95" "$BASE_P95" "$DELTA_PCT" "$CHECKS" \
    "$SCORE" "$TREND" "$RISK" "$STATUS" \
    >> "$EXEC_SUMMARY_CSV"

  ####################################
  # JSON
  ####################################
  jq -n \
    --arg test "$TEST" \
    --arg trend "$TREND" \
    --arg risk "$RISK" \
    --arg status "$STATUS" \
    --argjson p95 "$P95" \
    --argjson baseline_p95 "$BASE_P95" \
    --argjson delta_pct "$DELTA_PCT" \
    --argjson checks "$CHECKS" \
    --argjson score "$SCORE" \
    '{test:$test,p95:$p95,baseline_p95:$baseline_p95,delta_pct:$delta_pct,checks:$checks,score:$score,trend:$trend,risk:$risk,status:$status}' \
    >> "$EXEC_SUMMARY_JSON"

  echo "," >> "$EXEC_SUMMARY_JSON"

  ####################################
  # ATUALIZA BASELINE
  ####################################
  cp "$METRICS_FILE" "$BASELINE_FILE"

  echo ""
done

########################################
# FECHA JSON
########################################
sed -i '$ s/,$//' "$EXEC_SUMMARY_JSON"
echo "]" >> "$EXEC_SUMMARY_JSON"

########################################
# SCORE MÉDIO
########################################
AVG_SCORE=$(( TEST_COUNT > 0 ? TOTAL_SCORE / TEST_COUNT : 0 ))

########################################
# DASHBOARDS
########################################
./helpers/generate-index.sh "$EXPORT_DIR" || true
./helpers/generate-trends.sh "$ENV" || true

########################################
# FINAL
########################################
echo "======================================"
echo "📊 Performance Geral: $AVG_SCORE / 100"
echo "📁 CSV Executivo:  $EXEC_SUMMARY_CSV"
echo "📁 JSON Executivo: $EXEC_SUMMARY_JSON"
[ "$HAS_HIGH_RISK" -eq 1 ] && echo "⚠️ ATENÇÃO: Existem testes com RISCO HIGH"
echo "======================================"

exit 0
