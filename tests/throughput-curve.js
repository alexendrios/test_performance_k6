import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '1m', target: 10 },
    { duration: '1m', target: 25 },
    { duration: '1m', target: 50 },
    { duration: '1m', target: 75 },
    { duration: '1m', target: 100 },
    { duration: '1m', target: 150 },
    { duration: '1m', target: 200 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.05'],
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
    reportName: 'throughput-curve',
    testName: 'Throughput Curve – Products API',
  });
}
