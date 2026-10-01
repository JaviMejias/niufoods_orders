# Simulación de recepción en tienda

La API central selecciona la ruta de despacho usando el restaurante de la orden.
Un mismo servidor simula los tres locales, con una ruta distinta para cada uno:

- Providencia: `POST /api/v1/store/restaurants/1/orders`.
- Las Condes: `POST /api/v1/store/restaurants/2/orders`.
- Ñuñoa: `POST /api/v1/store/restaurants/3/orders`.

Los IDs anteriores corresponden al dataset inicial. El dispatcher utiliza el ID
real guardado en la orden, incluso si la base asigna IDs diferentes.

El receptor comprueba que el ID y el código del restaurante del payload coincidan
con el local indicado en la ruta. Confirma la recepción devolviendo `status:
"received"`, `order_id` y `restaurant_id`. La API verifica los tres campos antes de
marcar el despacho como `sent`. Una tienda distinta o una confirmación que no
corresponda a la orden deja el despacho como `error`.

## Ejecución local

Con las dependencias instaladas y los datos cargados, inicia la API central:

```bash
bin/rails server -p 3000
```

En otra terminal, inicia el simulador desde el mismo proyecto:

```bash
bin/rails server -p 3001 -P tmp/pids/store.pid
```

Ambos procesos deben usar la misma configuración de PostgreSQL. El archivo de PID
distinto permite mantener ambos servidores activos.

La dirección del simulador se configura con `STORE_BASE_URL`; por defecto es
`http://127.0.0.1:3001`. Esta variable reemplaza a `STORE_ORDERS_URL` y contiene
únicamente la dirección base. La ruta del restaurante se genera automáticamente.

```bash
STORE_BASE_URL=http://127.0.0.1:3001 bin/rails server -p 3000
```

Con ambos servidores activos puedes ejecutar el simulador de órdenes:

```bash
ruby script/simulate_orders.rb
```

El script envía una orden válida de retiro y otra de delivery por cada restaurante
cargado, con productos y cantidades aleatorios. Con los tres locales del dataset,
son seis órdenes válidas. Después envía tres solicitudes inválidas: nombre vacío,
restaurante inexistente y orden sin productos. Cada solicitud muestra el escenario,
el restaurante, el tipo de pedido, el código HTTP y el resultado de la API.

## Pruebas

```bash
bin/rails test test/integration/order_dispatch_test.rb
```

Las pruebas recorren creación, despacho y recepción para cada local usando los
controladores reales y un transporte HTTP simulado en memoria. También comprueban
rechazos por destinos incorrectos y confirmaciones de otra tienda u orden.
