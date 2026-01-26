import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '2m', target: 25 },
    { duration: '2m', target: 50 },
    { duration: '2m', target: 75 },
    { duration: '5m', target: 100 }, // 🎯 carga candidata à capacidade
  ],
  thresholds: {
    http_req_failed: ['rate<0.03'],       // SLA estrito
    http_req_duration: ['p(95)<1800'],     // latência máxima aceitável
  },
};

export default function () {
  const res = http.get('https://api.exemplo.com/products');

  check(res, {
    'status 200': r => r.status === 200,
  });

  sleep(1);
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'capacity',
    testName: 'Capacity Test – Products API',
  });
}
