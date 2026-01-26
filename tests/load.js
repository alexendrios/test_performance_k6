import http from 'k6/http'
import { sleep, check } from 'k6'
import { Trend } from 'k6/metrics'
import { buildSummary } from '../helpers/summary.helper.js';


// ==========================
// Configurações globais
// ==========================
const BASE_URL = __ENV.BASE_URL || 'https://dummyjson.com'

// Métrica customizada
const productsDuration = new Trend('products_duration')

// ==========================
// Opções do teste
// ==========================
export const options = {
  stages: [
    { duration: '1m', target: 100 },
    { duration: '2m', target: 200 },
    { duration: '1m', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate < 0.02'],        // até 2%
    http_req_duration: [
      'p(90) < 800',
      'p(95) < 1200',  //SLO
      'p(99) < 2000',  // SLA limit
    ],
  },
  summaryTrendStats: ['avg', 'p(90)', 'p(95)', 'p(99)', 'max'],
}

// ==========================
// Execução do teste
// ==========================
export default function () {
  const response = http.get(`${BASE_URL}/products`, {
    tags: { name: 'GET /products' },
  })

  // Validações
  check(response, {
    'status is 200': (r) => r.status === 200,
    'products list is not empty': (r) => r.json('products').length > 0,
  })

  // Métrica customizada
  productsDuration.add(response.timings.duration)

  // Think time
  sleep(1)
}


export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'load',
    testName: 'Load Test – Products API',
  });
}