import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:8000').replace(/\/$/, '');
const SALE_RATIO = Number(__ENV.SALE_RATIO || '0.05');

const apiErrors = new Counter('demo_api_errors');
const saleErrors = new Rate('demo_sale_error_rate');

export const options = {
  scenarios: {
    browsing: {
      executor: 'ramping-vus',
      stages: [
        { duration: '45s', target: Number(__ENV.WARMUP_VUS || 20) },
        { duration: '2m', target: Number(__ENV.PEAK_VUS || 120) },
        { duration: '2m', target: Number(__ENV.PEAK_VUS || 120) },
        { duration: '45s', target: 0 },
      ],
      gracefulRampDown: '20s',
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<750', 'p(99)<1500'],
    'http_req_duration{endpoint:clients-list}': ['p(95)<750'],
    'http_req_duration{endpoint:products-list}': ['p(95)<750'],
    'http_req_duration{endpoint:sales-list}': ['p(95)<1000'],
    demo_sale_error_rate: ['rate<0.05'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  getJson('/clients/api/client', 'clients-list');
  getJson('/products/api/product', 'products-list');
  getJson('/sales/resources/sale', 'sales-list');

  if (Math.random() < SALE_RATIO) {
    createSale();
  }

  sleep(Math.random() * 1.5);
}

function getJson(path, endpoint) {
  const res = http.get(`${BASE_URL}${path}`, {
    tags: { endpoint },
    timeout: '10s',
  });

  const ok = check(res, {
    [`${endpoint} status 200`]: (r) => r.status === 200,
    [`${endpoint} json`]: (r) => String(r.headers['Content-Type'] || '').includes('json'),
  });

  if (!ok) {
    apiErrors.add(1, { endpoint });
  }
}

function createSale() {
  const clientId = randomInt(1, 10);
  const productId1 = randomInt(1, 2);
  const productId2 = randomInt(1, 2);

  const payload = JSON.stringify({
    clientId,
    details: [
      { productId: productId1, count: randomInt(1, 3) },
      { productId: productId2, count: randomInt(1, 2) },
    ],
  });

  const res = http.post(`${BASE_URL}/sales/resources/sale`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { endpoint: 'sales-create' },
    timeout: '15s',
  });

  const ok = check(res, {
    'sales-create status 200 or 201': (r) => r.status === 200 || r.status === 201,
  });

  saleErrors.add(!ok);

  if (!ok) {
    apiErrors.add(1, { endpoint: 'sales-create' });
  }
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
