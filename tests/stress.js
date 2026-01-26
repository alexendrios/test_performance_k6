import http from 'k6/http'
import { sleep, check } from 'k6'
import { Trend } from 'k6/metrics'
import { buildSummary } from '../helpers/summary.helper.js';

// ==========================
// Configurações globais
// ==========================
const BASE_URL = __ENV.BASE_URL || 'https://dummyjson.com'
const productsDuration = new Trend('products_duration')

// ==========================
// Opções do teste (STRESS)
// ==========================
export const options = {
  stages: [
    { duration: '1m', target: 100 },  // carga normal
    { duration: '1m', target: 300 },  // acima do esperado
    { duration: '1m', target: 500 },  // stress real
    { duration: '1m', target: 800 },  // limite extremo
    { duration: '2m', target: 1000 },  // sustenta sob stress
    { duration: '1m', target: 0 },    // desligamento
  ],
  thresholds: {
    // Em stress test, thresholds são mais flexíveis
    http_req_failed: ['rate<0.05'],        // até 5% de erro aceitável
    http_req_duration: ['p(95)<2000'],     // latência pode degradar
  },
  summaryTrendStats: ['avg', 'p(90)', 'p(95)', 'p(99)', 'max'],
}

// ==========================
// Execução do teste
// ==========================
export default function () {
  const res = http.get(`${BASE_URL}/products`, {
    tags: { name: 'GET /products' },
  })

  check(res, {
    'status is 200': (r) => r.status === 200,
    'response has products': (r) => r.json('products')?.length > 0,
  })

  productsDuration.add(res.timings.duration)

  // Think time reduzido para aumentar pressão
  sleep(1)
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'stress',
    testName: 'Stress Test – Products API',
  });
}