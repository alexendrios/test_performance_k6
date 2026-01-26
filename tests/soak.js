import http from 'k6/http';
import { check, sleep } from 'k6';
import { buildSummary } from '../helpers/summary.helper.js';

export const options = {
  vus: 20,                 // carga estável
  duration: '30m',         // ⏳ duração longa (ajuste conforme necessidade)
  thresholds: {
    http_req_failed: ['rate<0.02'],        // < 1% erro ao longo do tempo
    http_req_duration: ['p(95)<1500'],      // latência não pode degradar
  },
};

export default function () {
  const res = http.get('https://api.exemplo.com/products');

  check(res, {
    'status 200': r => r.status === 200,
  });

  sleep(1); // importante para não virar stress escondido
}

export function handleSummary(data) {
  return buildSummary({
    data,
    reportName: 'soak',
    testName: 'Soak Test – Products API',
  });
}
