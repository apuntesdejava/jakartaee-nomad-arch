# k6 service tests

Scripts para probar cada servicio antes de Docker, en modo dev, y reutilizarlos contra Docker local/Fabio cambiando `BASE_URL`.

## Modo dev

```bash
k6 run load-tests/k6/service-products.js
k6 run load-tests/k6/service-clients.js
k6 run load-tests/k6/service-sales.js
```

Defaults:

```text
products: http://localhost:8080/products/api
clients:  http://localhost:8090/clients/api
sales:    http://localhost:8070/sales-app/resources
```

## Docker local / Fabio

```bash
BASE_URL=http://localhost:8000/products/api k6 run load-tests/k6/service-products.js
BASE_URL=http://localhost:8000/clients/api  k6 run load-tests/k6/service-clients.js
BASE_URL=http://localhost:8000/sales/resources k6 run load-tests/k6/service-sales.js
```

## Parametros

```bash
VUS=20 DURATION=2m CREATE_RATIO=0.02 k6 run load-tests/k6/service-products.js
```

Variables comunes:

- `BASE_URL`: base del servicio, sin el recurso final.
- `VUS`: usuarios virtuales. Default: `10`.
- `DURATION`: duracion de la prueba. Default: `1m`.
- `CREATE_RATIO`: porcentaje aproximado de iteraciones que hacen `POST`. Default: `0.05`.
- `SLEEP_SECONDS`: pausa entre iteraciones. Default: `1`.

Variables para ids:

- `MIN_CLIENT_ID`, `MAX_CLIENT_ID`.
- `MIN_PRODUCT_ID`, `MAX_PRODUCT_ID`.

Para `sales`, asegurate de que `clients` y `products` esten levantados y tengan datos en el rango configurado.
