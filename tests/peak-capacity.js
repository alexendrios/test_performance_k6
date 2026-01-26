import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '30s', target: 50 },
    { duration: '30s', target: 100 },
    { duration: '30s', target: 150 },
    { duration: '30s', target: 200 },
    { duration: '30s', target: 300 },
    { duration: '30s', target: 400 }, // 🚨 pico extremo
  ],
  thresholds: {
    http_req_failed: ['rate < 0.08'],
    http_req_duration: ['p(95) < 2500'],
  },
};

export default function () {
  const res = http.get('https://api.exemplo.com/products');

  check(res, {
    'status recebido': r => r.status !== 0, // não pode colapsar
  });

  sleep(1);
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'peak-capacity',
    testName: 'Peak Capacity Test – Products API',
  });
}
