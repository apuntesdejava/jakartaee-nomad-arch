import http from 'k6/http';
import { check, sleep } from 'k6';
import { randomString } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js';

export const options = {
  vus: 10, // 10 usuarios virtuales
  duration: '30s', // duración de la prueba de 30 segundos
  thresholds: {
    http_req_failed: ['rate<0.01'], // http errors should be less than 1%
    http_req_duration: ['p(95)<200'], // 95% of requests should be below 200ms
  },
};

export default function () {
  // Request 1: GET http://localhost:8080/api/product
  let res1 = http.get('http://localhost:8080/api/product');
  check(res1, {
    'GET /api/product status is 200': (r) => r.status === 200,
  });
  sleep(1);

  // Request 2: POST http://localhost:8080/api/product
  const productName = randomString(8);
  const productPrice = Math.random() * 100;
  const payload = JSON.stringify({
    name: productName,
    price: productPrice,
  });
  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };
  let res2 = http.post('http://localhost:8080/api/product', payload, params);
  check(res2, {
    'POST /api/product status is 201': (r) => r.status === 201,
  });

  const productId = res2.json('id');
  sleep(1);

  // Request 3: GET http://localhost:8080/api/product/{id}
  if (productId) {
    let res3 = http.get(`http://localhost:8080/api/product/${productId}`);
    check(res3, {
      'GET /api/product/{id} status is 200': (r) => r.status === 200,
    });
    sleep(1);
  }

/*
  // Request 4: GET http://localhost:8080/api/check-database
  let res4 = http.get('http://localhost:8080/api/check-database');
  check(res4, {
    'GET /api/check-database status is 200': (r) => r.status === 200,
  }); */
  sleep(1);
}