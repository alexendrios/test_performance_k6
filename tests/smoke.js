import http from 'k6/http'
import { sleep, check } from 'k6'
import { buildSummary } from '../helpers/k6-summary.helper.js';

// ==========================
// Opções do teste – SMOKE
// ==========================
export const options = {
  vus: 1,
  duration: '30s', // curto e objetivo
  thresholds: {
    http_req_failed: ['rate < 0.01'],     // < 1% erro
    http_req_duration: ['p(95) < 800'],   // resposta rápida
  },
}

// ==========================
// Execução do teste
// ==========================
export default function () {
  const res = http.get('https://dummyjson.com/products', {
    tags: { name: 'GET /products' },
  })

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response has products': (r) => r.json('products')?.length > 0,
  })

  sleep(1)
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'smoke',
    testName: 'Smoke Test – Products API',
  });
}