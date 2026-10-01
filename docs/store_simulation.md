# Simulación de órdenes y recepción en tienda

La API central selecciona la ruta de despacho usando el restaurante de la orden.
La [instalación y configuración](../README.md#instalación-y-configuración) y los
[diagramas del flujo](architecture.md) se describen en la documentación principal.
Un mismo servidor simula los tres locales, con una ruta distinta para cada uno:

- Providencia: `POST /api/v1/store/restaurants/1/orders`.
- Las Condes: `POST /api/v1/store/restaurants/2/orders`.
- Ñuñoa: `POST /api/v1/store/restaurants/3/orders`.

Los IDs anteriores corresponden al catálogo inicial en una base nueva.
`OrderDispatcher` utiliza el ID real guardado en la orden, incluso si la base
asigna IDs diferentes.

El receptor comprueba que el ID y el código del restaurante del payload coincidan
con el local indicado en la ruta. Confirma la recepción devolviendo
`status: "received"`, `order_id` y `restaurant_id`. La API verifica los tres campos
antes de marcar el despacho como `sent`. Una tienda distinta o una confirmación
que no corresponda a la orden deja el despacho como `error`.

## Ejecución local

Completar la [instalación](installation.md) y cargar el catálogo antes de iniciar
la simulación. En Ubuntu y Windows con WSL, ejecutar los siguientes comandos
en terminales de Ubuntu, desde la raíz del repositorio `niufoods_orders`.

En la primera terminal, iniciar la API central:

```bash
bin/rails server -b 127.0.0.1 -p 3000
```

En la segunda terminal, iniciar el receptor de tienda:

```bash
bin/rails server -b 127.0.0.1 -p 3001 -P tmp/pids/store.pid
```

Ambos procesos deben usar la misma configuración de PostgreSQL. El archivo de PID
distinto permite mantener ambos servidores activos. El receptor solo consulta el
restaurante y responde una confirmación; no guarda una segunda orden ni sus ítems.

La dirección del receptor se configura con `STORE_BASE_URL`; por defecto es
`http://127.0.0.1:3001`. Contiene únicamente la dirección base. La ruta del
restaurante se genera automáticamente. Para cambiar esa dirección, asignar la
variable al iniciar la API central, sustituyendo su comando de inicio. Por ejemplo,
para indicar explícitamente la dirección local:

```bash
STORE_BASE_URL=http://127.0.0.1:3001 bin/rails server -b 127.0.0.1 -p 3000
```

## Generar pedidos

Con ambos servidores activos, ejecutar el script en otra terminal desde la raíz:

```bash
ruby script/simulate_orders.rb
```

El script envía una orden válida de retiro y otra de delivery por cada restaurante
cargado, con entre uno y cuatro productos y cantidades entre uno y cinco. Con los
tres locales del catálogo, son seis órdenes válidas. Después envía tres solicitudes
inválidas: nombre vacío, restaurante inexistente y orden sin productos. Cada
solicitud muestra el escenario, el restaurante, el tipo de pedido, el código HTTP
y el resultado de la API.
Cada ejecución agrega nuevas órdenes válidas a la base de desarrollo. El script
requiere datos y una API disponible en `http://127.0.0.1:3000`. Esa dirección está
definida en `script/simulate_orders.rb`.

### Resultados esperados

| Escenario | Respuesta | Resultado |
| --- | --- | --- |
| Pedido válido, receptor disponible | HTTP 201, `dispatch_status: "sent"` | La orden se guarda y la tienda confirma la recepción |
| Pedido válido, receptor caído | HTTP 201, `dispatch_status: "error"` | La orden se guarda y se registra el fallo de despacho |
| Nombre vacío, restaurante inexistente o pedido sin productos | HTTP 422 | La solicitud se rechaza y no se guarda la orden |

Con el catálogo inicial y ambos servidores activos, se esperan seis respuestas
HTTP 201 y tres HTTP 422. Recargar el dashboard para ver los pedidos nuevos.

El script muestra las respuestas de la API y no reintenta solicitudes. Si la API
central está caída, termina con un error de conexión.

## Pruebas

Desde la raíz del repositorio:

```bash
bin/rails test test/integration/order_dispatch_test.rb
```

Las pruebas recorren creación, despacho y recepción para cada local usando los
controladores reales y un transporte HTTP simulado en memoria. También comprueban
rechazos por destinos incorrectos y confirmaciones de otra tienda u orden.
