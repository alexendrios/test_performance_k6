#!/bin/bash
set -e

########################################
# VALIDACAO
########################################
EXPORT_DIR="$1"

if [ -z "$EXPORT_DIR" ]; then
  echo "❌ Uso: generate-index.sh <EXPORT_DIR>"
  exit 0
fi

EXPORT_DIR="$(cd "$EXPORT_DIR" && pwd)"
SUMMARY_JSON="$EXPORT_DIR/summary.json"
OUTPUT_HTML="$EXPORT_DIR/index.html"

if [ ! -f "$SUMMARY_JSON" ]; then
  echo "⚠️ summary.json não encontrado em $EXPORT_DIR"
  exit 0
fi

########################################
# HTML HEADER
########################################
cat <<'EOF' > "$OUTPUT_HTML"
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>Dashboard de Performance</title>
<style>
body {
  font-family: Arial, sans-serif;
  background: #020617;
  color: #e5e7eb;
  padding: 30px;
}
h1 {
  color: #38bdf8;
}
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}
th, td {
  padding: 12px;
  border-bottom: 1px solid #1e293b;
  text-align: center;
}
th {
  background: #020617;
  color: #94a3b8;
}
tr:hover {
  background: #020617;
}
.badge {
  padding: 6px 14px;
  border-radius: 999px;
  font-weight: bold;
  font-size: 12px;
}
.LOW    { background: #4ade80; color: #022c22; }
.MEDIUM { background: #facc15; color: #422006; }
.HIGH   { background: #f87171; color: #450a0a; }
.OK     { background: #22c55e; color: #052e16; }
.FAIL   { background: #ef4444; color: #450a0a; }

a {
  color: #38bdf8;
  text-decoration: none;
}
.footer {
  margin-top: 30px;
  color: #64748b;
  font-size: 12px;
}
</style>
</head>
<body>

<h1>📊 Dashboard de Performance</h1>

<table>
<thead>
<tr>
  <th>Teste</th>
  <th>P95 (ms)</th>
  <th>Baseline P95</th>
  <th>Δ %</th>
  <th>Checks</th>
  <th>Score</th>
  <th>Trend</th>
  <th>Risco</th>
  <th>Status</th>
  <th>Relatório</th>
</tr>
</thead>
<tbody>
EOF

########################################
# CONTEÚDO DINÂMICO
########################################
jq -c '.[]' "$SUMMARY_JSON" | while read -r row; do
  TEST=$(echo "$row" | jq -r '.test')
  P95=$(echo "$row" | jq -r '.p95')
  BASE=$(echo "$row" | jq -r '.baseline_p95')
  DELTA=$(echo "$row" | jq -r '.delta_pct')
  CHECKS=$(echo "$row" | jq -r '.checks')
  SCORE=$(echo "$row" | jq -r '.score')
  TREND=$(echo "$row" | jq -r '.trend')
  RISK=$(echo "$row" | jq -r '.risk')
  STATUS=$(echo "$row" | jq -r '.status')

  REPORT_LINK="./${TEST}-report.html"


  cat <<EOF >> "$OUTPUT_HTML"
<tr>
  <td><strong>$TEST</strong></td>
  <td>${P95}</td>
  <td>${BASE}</td>
  <td>${DELTA}%</td>
  <td>${CHECKS}%</td>
  <td>${SCORE}</td>
  <td>${TREND}</td>
  <td><span class="badge ${RISK}">${RISK}</span></td>
  <td><span class="badge ${STATUS}">${STATUS}</span></td>
  <td><a href="$REPORT_LINK" target="_blank">📄 Abrir</a></td>
</tr>
EOF
done

########################################
# HTML FOOTER
########################################
cat <<EOF >> "$OUTPUT_HTML"
</tbody>
</table>

<div class="footer">
Gerado automaticamente • k6 Performance Suite
</div>

</body>
</html>
EOF

echo "✅ Dashboard gerado: $OUTPUT_HTML"
