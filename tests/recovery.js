import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '20s', target: 2 },    // baseline
    { duration: '20s', target: 200 },  // 💥 stress forte
    { duration: '40s', target: 2 },    // 🔄 recovery
  ],
  thresholds: {
    http_req_failed: ['rate < 0.02'],
    http_req_duration: ['p(95) < 1200'], // deve voltar ao normal
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
    reportName: 'recovery',
    testName: 'Recovery Test – Products API',
  });
}

