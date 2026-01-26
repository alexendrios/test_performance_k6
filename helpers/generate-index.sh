#!/bin/bash

ENV=${ENV:-dev}
BASE_DIR="results/$ENV"
INDEX_FILE="reports/index.html"

mkdir -p reports

cat <<EOF > $INDEX_FILE
<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<title>K6 Dashboard - $ENV</title>
<style>
body {
  font-family: Arial, sans-serif;
  background: #0f172a;
  color: #e5e7eb;
  padding: 40px;
}
h1 { color: #38bdf8; }
.env { color: #a5b4fc; }
table {
  width: 100%;
  border-collapse: collapse;
  margin-top: 20px;
}
th, td {
  padding: 12px;
  border-bottom: 1px solid #334155;
}
tr:hover { background: #1e293b; }
.badge-ok { color: #22c55e; font-weight: bold; }
.badge-fail { color: #ef4444; font-weight: bold; }
.badge-error { color: #f97316; font-weight: bold; }
.date { color: #94a3b8; font-size: 0.9em; }
</style>
</head>
<body>

<h1>📊 K6 – Dashboard de Performance</h1>
<p class="env">Ambiente: <strong>$ENV</strong></p>

<table>
<thead>
<tr>
  <th>Execução</th>
  <th>Teste</th>
  <th>Status</th>
  <th>Tipo</th>
</tr>
</thead>
<tbody>
EOF

for RUN in $(ls -dt $BASE_DIR/* 2>/dev/null); do
  RUN_ID=$(basename "$RUN")
  STATUS_FILE="$RUN/status.csv"

  [ ! -f "$STATUS_FILE" ] && continue

  while IFS=',' read -r TEST STATUS TYPE; do
    [[ "$TEST" == "test" ]] && continue

    case $TYPE in
      success)
        BADGE="<span class='badge-ok'>✅ OK</span>"
        ;;
      threshold)
        BADGE="<span class='badge-fail'>❌ Threshold</span>"
        ;;
      technical)
        BADGE="<span class='badge-error'>💥 Técnico</span>"
        ;;
    esac

    echo "<tr>
      <td class='date'>$RUN_ID</td>
      <td>$TEST</td>
      <td>$BADGE</td>
      <td>$TYPE</td>
    </tr>" >> $INDEX_FILE

  done < "$STATUS_FILE"
done

cat <<EOF >> $INDEX_FILE
</tbody>
</table>

</body>
</html>
EOF

echo "✅ Dashboard gerado: $INDEX_FILE"
