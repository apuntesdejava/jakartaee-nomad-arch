import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:8070/sales/resources').replace(/\/$/, '');
const VUS = Number(__ENV.VUS || '10');
const DURATION = __ENV.DURATION || '1m';
const CREATE_RATIO = Number(__ENV.CREATE_RATIO || '0.05');
const MIN_CLIENT_ID = Number(__ENV.MIN_CLIENT_ID || '1');
const MAX_CLIENT_ID = Number(__ENV.MAX_CLIENT_ID || '10');
const MIN_PRODUCT_ID = Number(__ENV.MIN_PRODUCT_ID || '1');
const MAX_PRODUCT_ID = Number(__ENV.MAX_PRODUCT_ID || '10');

const apiErrors = new Counter('sales_api_errors');
const createErrorRate = new Rate('sales_create_error_rate');

export const options = {
  scenarios: {
    sales: {
      executor: 'constant-vus',
      vus: VUS,
      duration: DURATION,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<1000', 'p(99)<2000'],
    'http_req_duration{endpoint:sales-list}': ['p(95)<1000'],
    sales_create_error_rate: ['rate<0.05'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  getJson('/sale', 'sales-list');

  if (Math.random() < CREATE_RATIO) {
    createSale();
  }

  sleep(Number(__ENV.SLEEP_SECONDS || '1'));
}

function getJson(path, endpoint) {
  const res = http.get(`${BASE_URL}${path}`, {
    tags: { endpoint },
    timeout: '15s',
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
  const payload = JSON.stringify({
    clientId: randomInt(MIN_CLIENT_ID, MAX_CLIENT_ID),
    totalPrice: 0,
    details: [
      {
        productId: randomInt(MIN_PRODUCT_ID, MAX_PRODUCT_ID),
        count: randomInt(1, 3),
      },
      {
        productId: randomInt(MIN_PRODUCT_ID, MAX_PRODUCT_ID),
        count: randomInt(1, 2),
      },
    ],
  });

  const res = http.post(`${BASE_URL}/sale`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { endpoint: 'sales-create' },
    timeout: '20s',
  });

  const ok = check(res, {
    'sales-create status 201': (r) => r.status === 201,
    'sales-create json': (r) => String(r.headers['Content-Type'] || '').includes('json'),
  });

  createErrorRate.add(!ok);

  if (!ok) {
    apiErrors.add(1, { endpoint: 'sales-create' });
  }
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
