#!/bin/bash

ENV=${1:-dev}
BASE_DIR="results/$ENV"
OUTPUT="reports/trends.html"

mkdir -p reports

DATA=$(
for RUN in $(ls -dt "$BASE_DIR"/* 2>/dev/null); do
  RUN_ID=$(basename "$RUN")
  for METRICS in "$RUN"/*-metrics.json; do
    TEST=$(basename "$METRICS" | sed 's/-metrics.json//')
    [ ! -s "$METRICS" ] && continue
    P95=$(jq -r '
  if type=="object" and has("http_req_duration_p95") and (.http_req_duration_p95 | type=="number")
  then .http_req_duration_p95
  else empty
  end
' "$METRICS" 2>/$ENV/null)

    echo "$RUN_ID,$TEST,$P95"
  done
done
)

cat <<EOF > "$OUTPUT"
<!DOCTYPE html>
<html>
<head>
<meta charset="UTF-8">
<title>K6 Trends</title>
<script src="https://cdn.jsdelivr.net/npm/chart.js"></script>
</head>
<body style="background:#0f172a;color:white;padding:30px;font-family:Arial">
<h2>📉 Tendência P95 – $ENV</h2>
<canvas id="chart"></canvas>
<script>
const data = [
$(echo "$DATA" | awk -F',' '{print "{x:\""$1" ("$2")\",y:"$3"},"}')
];
new Chart(document.getElementById('chart'), {
  type: 'line',
  data: { datasets: [{ label: 'P95 (ms)', data, tension: 0.3 }] }
});
</script>
</body>
</html>
EOF

echo "📈 Trends gerado: $OUTPUT"
