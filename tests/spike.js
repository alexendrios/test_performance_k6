import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  stages: [
    { duration: '20s', target: 2 },    // baseline
    { duration: '10s', target: 150 },  // 🚀 spike súbito
    { duration: '30s', target: 2 },    // recuperação
  ],
  thresholds: {
    http_req_failed: ['rate<0.10'],        // até 10% de erro
    http_req_duration: ['p(95)<3000'],      // SLA sob stress
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
    reportName: 'spike',
    testName: 'Spike Test – Products APII',
  });
}