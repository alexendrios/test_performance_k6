#!/bin/bash
set +e

RAW_SUMMARY="$1"

if [ -z "$RAW_SUMMARY" ] || [ ! -f "$RAW_SUMMARY" ]; then
  echo "Uso: normalize-metrics.sh <summary.json>" >&2
  exit 1
fi

OUTPUT_FILE="${RAW_SUMMARY%-summary.json}-metrics.json"

jq '
{
  http_req_duration_p95: (.metrics.http_req_duration["p(95)"] // 0) | tonumber,
  http_req_failed_rate: (.metrics.http_req_failed.value // 0) | tonumber,
  checks_pass_rate: (if (.metrics.checks and (.metrics.checks.passes + .metrics.checks.fails) > 0) then ((.metrics.checks.passes*100)/(.metrics.checks.passes+.metrics.checks.fails)) else 0 end),
  vus_max: (.metrics.vus_max.value // 0) | tonumber
}
' "$RAW_SUMMARY" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "📊 Métricas normalizadas salvas em: $OUTPUT_FILE"
else
  echo "⚠️ Falha ao normalizar métricas" >&2
fi
#!/bin/bash
set +e

RAW_SUMMARY="$1"

if [ -z "$RAW_SUMMARY" ] || [ ! -f "$RAW_SUMMARY" ]; then
  echo "Uso: normalize-metrics.sh <summary.json>" >&2
  exit 1
fi

OUTPUT_FILE="${RAW_SUMMARY%-summary.json}-metrics.json"

# ==============================
# Extrai métricas de forma segura
# ==============================
jq '{
  http_req_duration_p95: (if has("metrics") and .metrics.http_req_duration and .metrics.http_req_duration["p(95)"] != null then .metrics.http_req_duration["p(95)"] else 0 end | tonumber),
  http_req_failed_rate: (if has("metrics") and .metrics.http_req_failed and .metrics.http_req_failed.value != null then .metrics.http_req_failed.value else 0 end | tonumber),
  checks_pass_rate: (if has("metrics") and .metrics.checks and (.metrics.checks.passes + .metrics.checks.fails) > 0 then ((.metrics.checks.passes * 100) / (.metrics.checks.passes + .metrics.checks.fails)) else 0 end | tonumber),
  vus_max: (if has("metrics") and .metrics.vus_max and .metrics.vus_max.value != null then .metrics.vus_max.value else 0 end | tonumber)
}' "$RAW_SUMMARY" > "$OUTPUT_FILE"

if [ $? -eq 0 ]; then
  echo "📊 Métricas normalizadas salvas em: $OUTPUT_FILE"
else
  echo "⚠️ Falha ao normalizar métricas" >&2
fi
