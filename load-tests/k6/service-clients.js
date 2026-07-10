import http from 'k6/http';
import { check, sleep } from 'k6';
import { Counter, Rate } from 'k6/metrics';

const BASE_URL = (__ENV.BASE_URL || 'http://localhost:8090/clients/api').replace(/\/$/, '');
const VUS = Number(__ENV.VUS || '10');
const DURATION = __ENV.DURATION || '1m';
const CREATE_RATIO = Number(__ENV.CREATE_RATIO || '0.05');
const MIN_ID = Number(__ENV.MIN_CLIENT_ID || '1');
const MAX_ID = Number(__ENV.MAX_CLIENT_ID || '10');

const apiErrors = new Counter('clients_api_errors');
const createErrorRate = new Rate('clients_create_error_rate');

export const options = {
  scenarios: {
    clients: {
      executor: 'constant-vus',
      vus: VUS,
      duration: DURATION,
    },
  },
  thresholds: {
    http_req_failed: ['rate<0.02'],
    http_req_duration: ['p(95)<750', 'p(99)<1500'],
    'http_req_duration{endpoint:clients-list}': ['p(95)<750'],
    'http_req_duration{endpoint:clients-find}': ['p(95)<750'],
    clients_create_error_rate: ['rate<0.05'],
  },
  summaryTrendStats: ['min', 'avg', 'med', 'p(90)', 'p(95)', 'p(99)', 'max'],
};

export default function () {
  getJson('/client', 'clients-list');
  getJson(`/client/${randomInt(MIN_ID, MAX_ID)}`, 'clients-find');

  if (Math.random() < CREATE_RATIO) {
    createClient();
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

function createClient() {
  const id = `${__VU}-${__ITER}-${Date.now()}`;
  const payload = JSON.stringify({
    firstName: `Demo${id}`,
    lastName: 'JConf',
    email: `demo-${id}@example.com`,
  });

  const res = http.post(`${BASE_URL}/client`, payload, {
    headers: { 'Content-Type': 'application/json' },
    tags: { endpoint: 'clients-create' },
    timeout: '10s',
  });

  const ok = check(res, {
    'clients-create status 201': (r) => r.status === 201,
    'clients-create json': (r) => String(r.headers['Content-Type'] || '').includes('json'),
  });

  createErrorRate.add(!ok);

  if (!ok) {
    apiErrors.add(1, { endpoint: 'clients-create' });
  }
}

function randomInt(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}
