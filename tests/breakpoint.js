import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '30s', target: 10 },
    { duration: '30s', target: 25 },
    { duration: '30s', target: 50 },
    { duration: '30s', target: 75 },
    { duration: '30s', target: 100 },
    { duration: '30s', target: 150 },
    { duration: '30s', target: 200 }, // 💣 provável breakpoint
  ],
  thresholds: {
    http_req_failed: ['rate < 0.15'],
    http_req_duration: ['p(95) < 4000'],    // SLA limite
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
    reportName: 'breakpoint',
    testName: 'Breakpoint Test – Products API',
  });
}
