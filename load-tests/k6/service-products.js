import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:8080/products/api').replace(/\/$/, '');
const VUS = Number(__ENV.VUS || '10');
const DURATION = __ENV.DURATION || '1m';
const CREATE_RATIO = Number(__ENV.CREATE_RATIO || '0.05');
const MIN_ID = Number(__ENV.MIN_PRODUCT_ID || '1');
const MAX_ID = Number(__ENV.MAX_PRODUCT_ID || '10');

const apiErrors = new Counter('products_api_errors');
const createErrorRate = new Rate('products_create_error_rate');

export const options = {
  scenarios: {
    products: {
      executor: 'constant-vus',
      vus: VUS,
      duration: DURATION,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<750', 'p(99)<1500'],
    'http_req_duration{endpoint:products-list}': ['p(95)<750'],
    'http_req_duration{endpoint:products-find}': ['p(95)<750'],
    products_create_error_rate: ['rate<0.05'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  getJson('/product', 'products-list');
  getJson(`/product/${randomInt(MIN_ID, MAX_ID)}`, 'products-find');

  if (Math.random() < CREATE_RATIO) {
    createProduct();
  }

  sleep(Number(__ENV.SLEEP_SECONDS || '1'));
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

function createProduct() {
  const id = `${__VU}-${__ITER}-${Date.now()}`;
  const payload = JSON.stringify({
    name: `Demo product ${id}`,
    price: Number((randomInt(100, 5000) / 10).toFixed(2)),
  });

  const res = http.post(`${BASE_URL}/product`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { endpoint: 'products-create' },
    timeout: '10s',
  });

  const ok = check(res, {
    'products-create status 201': (r) => r.status === 201,
    'products-create json': (r) => String(r.headers['Content-Type'] || '').includes('json'),
  });

  createErrorRate.add(!ok);

  if (!ok) {
    apiErrors.add(1, { endpoint: 'products-create' });
  }
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
