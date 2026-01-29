import http from 'k6/http'
import { sleep, check } from 'k6'
import { buildSummary } from '../helpers/k6-summary.helper.js';


export const options = {
  vus: 10,
  duration: '30s',
  thresholds: {
    http_req_failed: ['rate < 0.01'],
    http_req_duration: ['p(95) < 1000'],
  },
}

export default function () {
  const res = http.get('https://dummyjson.com/products', {
    tags: { name: 'GET /products' },
  })

  check(res, {
    'status is 200': (r) => r.status === 200,
    'products list is not empty': (r) => r.json('products')?.length > 0,
  })

  sleep(1)
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'sanity-load',
    testName: 'Sanity Load Test – Products API',
  });
}
