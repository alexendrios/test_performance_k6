#!/usr/bin/env bash
set -Eeuo pipefail

########################################
# ARGUMENTOS
########################################
TEST="${1:-}"
RUN_DIR="${2:-}"
EXPORT_DIR="${3:-}"

if [[ -z "$TEST" || -z "$RUN_DIR" || -z "$EXPORT_DIR" ]]; then
  echo "❌ Uso:"
  echo "   generate-test-report.sh <test> <run_dir> <export_dir>"
  exit 1
fi

########################################
# PATHS
########################################
METRICS_FILE="$RUN_DIR/${TEST}-metrics.json"
REPORT_FILE="$EXPORT_DIR/${TEST}-report.html"
DASHBOARD_LINK="./index.html"

mkdir -p "$EXPORT_DIR"

########################################
# VALIDA METRICS
########################################
if [ ! -f "$METRICS_FILE" ]; then
  echo "⚠️ Metrics não encontrado: $METRICS_FILE"
  exit 0
fi

########################################
# MÉTRICAS
########################################
P95="$(jq -r '.http_req_duration_p95 // 0' "$METRICS_FILE")"
FAIL_RATE="$(jq -r '.http_req_failed_rate // 0' "$METRICS_FILE")"
CHECKS="$(jq -r '.checks_pass_rate // 0' "$METRICS_FILE")"
VUS="$(jq -r '.vus_max // 0' "$METRICS_FILE")"

FAIL_RATE_PCT="$(awk "BEGIN {printf \"%.2f\", $FAIL_RATE * 100}")"

########################################
# STATUS
########################################
STATUS="PASS"
BADGE_COLOR="#4ade80"

awk -v f="$FAIL_RATE" -v c="$CHECKS" 'BEGIN {
  if (f > 0 || c < 100) exit 1
}' || {
  STATUS="FAIL"
  BADGE_COLOR="#f87171"
}

########################################
# HTML
########################################
cat <<EOF > "$REPORT_FILE"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Relatório – $TEST</title>
<style>
body { font-family: Arial; background:#0f172a; color:#e5e7eb; padding:30px }
h1 { color:#38bdf8 }
.card { background:#1e293b; padding:20px; border-radius:10px; max-width:600px }
.badge {
  padding:6px 14px;
  border-radius:999px;
  font-weight:bold;
  background:$BADGE_COLOR;
  color:#020617;
}
a { color:#38bdf8; text-decoration:none }
</style>
</head>
<body>

<a href="$DASHBOARD_LINK">⬅ Voltar ao Dashboard</a>

<h1>📄 Relatório – $TEST</h1>
<span class="badge">$STATUS</span>

<div class="card">
  <p><strong>P95:</strong> ${P95} ms</p>
  <p><strong>Erro HTTP:</strong> ${FAIL_RATE_PCT}%</p>
  <p><strong>Checks:</strong> ${CHECKS}%</p>
  <p><strong>VUs Máximos:</strong> ${VUS}</p>
</div>

</body>
</html>
EOF

echo "✅ Report gerado: $REPORT_FILE"
