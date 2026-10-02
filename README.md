# Órdenes Niu Foods

Proyecto para la prueba técnica de integración y distribución de órdenes de Niu Foods.
La API en Ruby on Rails recibe pedidos, valida sus datos, calcula el total y los
guarda en PostgreSQL. Luego envía cada pedido al restaurante correspondiente.
El dashboard en React permite revisar las órdenes y consultar sus detalles.

## Documentación

- [Instalación en Ubuntu o Windows con WSL](docs/installation.md).
- [Arquitectura, modelo de datos y flujo de una orden](docs/architecture.md).
- [Referencia de la API y ejemplos de respuestas](docs/api.md).
- [Script de órdenes y receptor de tienda](docs/store_simulation.md).
- [Dashboard: ejecución y funcionamiento](frontend/README.md).
- [Criterios de diseño visual](DESIGN.md).

## Requisitos

El proyecto se desarrolló en Ubuntu 26.04 con WSL 2. Estas son las versiones
utilizadas:

| Componente | Versión |
| --- | --- |
| Ruby | 3.4.11, indicada en `.ruby-version` |
| Bundler | 4.0.21, indicada en `Gemfile.lock` |
| Rails | 8.1.4 |
| PostgreSQL | 18.6 |
| Node.js | 22.22.1 |
| pnpm | 12.8.1 |
| React / Vite | 19.3.0 / 8.3.1 |

Ruby se selecciona mediante `.ruby-version`; las dependencias de Rails y del
frontend están fijadas en `Gemfile.lock` y `frontend/pnpm-lock.yaml`.
PostgreSQL debe estar en ejecución. Los ejemplos HTTP utilizan `curl`.

## Instalación y configuración

Seguir la [guía de instalación](docs/installation.md) según el entorno:

- **Ubuntu:** [preparar las herramientas en Linux](docs/installation.md#ubuntu).
- **Windows:** [instalar o abrir Ubuntu en WSL 2](docs/installation.md#windows-con-wsl-2)
  y continuar los pasos dentro de esa terminal.
- **Herramientas ya instaladas:** ir a [configurar el proyecto](docs/installation.md#configurar-el-proyecto).

La guía incluye Ruby, Node.js, pnpm, PostgreSQL, las dependencias del proyecto y
la carga inicial de restaurantes y productos. En una base nueva, el dashboard
parte sin órdenes.

Todas las rutas del proyecto se indican respecto del repositorio `niufoods_orders`.
En los pasos siguientes, «desde la raíz» significa estar dentro de esa carpeta.

## Ejecutar la solución

Mantener tres terminales abiertas. Los dos servidores Rails utilizan el mismo
proyecto y la misma base de desarrollo; representan la API central y el receptor
simulado mediante procesos separados.

**Terminal 1 — API central, desde la raíz:**

```bash
bin/rails server -b 127.0.0.1 -p 3000
```

**Terminal 2 — tienda simulada, desde la raíz:**

```bash
bin/rails server -b 127.0.0.1 -p 3001 -P tmp/pids/store.pid
```

El archivo de PID distinto permite ejecutar ambos procesos al mismo tiempo.
El receptor recibe pedidos en una ruta específica para cada restaurante.

**Terminal 3 — dashboard, desde la raíz:**

```bash
cd frontend
pnpm dev
```

Abrir la dirección indicada por Vite, normalmente `http://localhost:5173`.
Vite redirige `/api` a `http://127.0.0.1:3000`, así que el navegador consulta la API
mediante el mismo origen. Para revisar pedidos guardados basta con la API y Vite;
para probar un despacho exitoso también debe estar disponible la tienda simulada.

Para configurar el destino de despacho, asignar `STORE_BASE_URL` al iniciar la
API central. Este comando sustituye al de la terminal 1:

```bash
STORE_BASE_URL=http://127.0.0.1:3001 bin/rails server -b 127.0.0.1 -p 3000
```

`STORE_BASE_URL` es una dirección base y su valor predeterminado es el del ejemplo.
La ruta `/api/v1/store/restaurants/:restaurant_id/orders` se construye a partir
del restaurante guardado en cada orden. El script generador consulta la API central
en `http://127.0.0.1:3000`.

## Probar el flujo completo

Con la API y el receptor activos, abrir una cuarta terminal y ejecutar desde la raíz:

```bash
ruby script/simulate_orders.rb
```

Con el catálogo inicial genera seis pedidos válidos: retiro y delivery para cada
restaurante. Después envía tres solicitudes inválidas: nombre vacío, restaurante
inexistente y pedido sin productos. Los pedidos usan entre uno y cuatro productos
y cantidades entre uno y cinco.

Se esperan seis respuestas HTTP 201 con `dispatch_status: "sent"` y tres HTTP 422
con errores de validación. Cada ejecución guarda nuevas órdenes válidas. Si la
tienda no está disponible, las órdenes válidas igualmente se guardan y responden
HTTP 201, pero quedan con `dispatch_status: "error"`.

Recargar el dashboard para consultar las nuevas órdenes. El listado muestra número,
restaurante, total, modalidad, fecha y estado de despacho, con scroll infinito y
botón **Cargar más**. Seleccionar el número abre el detalle con los datos del cliente
y los productos del pedido.
La interfaz usa español de Chile, pesos chilenos y la zona horaria `America/Santiago`.

## Ejemplos de API

Crear una orden de delivery con el catálogo inicial:

```bash
curl -i http://127.0.0.1:3000/api/v1/orders \
  -H 'Content-Type: application/json' \
  -H 'Accept: application/json' \
  --data '{
    "restaurant_id": 2,
    "order_type": "delivery",
    "customer": { "name": "Ana Pérez", "phone": "+56912345678" },
    "delivery_address": "Av. Providencia 1234, Santiago",
    "items": [
      { "product_id": 1, "quantity": 2 },
      { "product_id": 5, "quantity": 1 }
    ]
  }'
```

El total calculado con los precios iniciales es **$22.470 CLP**. La respuesta incluye
el ID generado y el estado del despacho. Los IDs de restaurante y producto del
ejemplo corresponden a una base recién creada; si ya existían registros, consultar
los IDs reales:

```bash
bin/rails runner 'puts JSON.pretty_generate(restaurants: Restaurant.order(:id).as_json(only: %i[id code name]), products: Product.order(:id).as_json(only: %i[id sku name price_clp]))'
```

Consultar el listado y el detalle; reemplazar `1` por el ID devuelto al crear:

```bash
curl -i 'http://127.0.0.1:3000/api/v1/orders?page=1&per_page=20'
curl -i http://127.0.0.1:3000/api/v1/orders/1
```

La [referencia de API](docs/api.md) describe los campos, la paginación y los errores.

## Pruebas y comprobaciones

Desde la raíz, con PostgreSQL disponible:

```bash
bin/rails test
bin/rubocop
bin/brakeman --no-pager
bin/bundler-audit check --update
```

Las pruebas de integración cubren cálculo de totales, precios enviados por el
cliente, modalidad inválida, fallos de conexión,
despacho a los tres restaurantes, confirmaciones incorrectas, validación del
receptor y detalle del pedido con precios guardados. Simulan el transporte HTTP;
no requieren levantar servidores ni utilizan la base de desarrollo.

Desde `frontend/`:

```bash
pnpm test
pnpm lint
pnpm build
```

Las pruebas del frontend cubren paginación, combinación de páginas, reintentos,
cancelación de solicitudes HTTP y consulta del detalle. La interacción con la tabla
y el modal se comprueba en el navegador mediante el flujo descrito arriba.

GitHub Actions ejecuta las pruebas, los controles de estilo y el análisis de
seguridad del backend, además de las pruebas, lint y build del frontend.

## Decisiones técnicas y alcance

- Rails funciona como API y React reside en `frontend/`, con dependencias y build propios.
- Los modelos validan los datos y los strong params delimitan los campos aceptados.
  El total y los precios unitarios se calculan en el servidor.
- Cada ítem guarda su precio unitario al crear la orden. El detalle conserva esos
  montos aunque posteriormente cambie el precio del producto en el catálogo.
- El despacho es síncrono y ocurre después de guardar el pedido. Una confirmación
  debe coincidir con la orden y su restaurante; un fallo se registra sin borrar la orden.
- Un proceso receptor simula los tres locales usando rutas por restaurante. No guarda
  una segunda copia del pedido ni representa un sistema de cocina completo.
- La API usa paginación por offset y el dashboard añade páginas sin duplicar IDs.
  El detalle se consulta al abrir el modal, manteniendo liviana la respuesta del listado.
- No se implementaron Sidekiq, reintentos automáticos ni actualizaciones en tiempo real.
  El estado `sent` confirma el envío, no la preparación o entrega del pedido.
- La API permite crear y consultar órdenes. La cancelación de pedidos queda fuera
  del alcance de esta prueba.

Los [diagramas y el flujo](docs/architecture.md) explican estas decisiones y sus límites.
`pnpm build` genera el frontend en `frontend/dist/`. Para publicarlo, el servidor
de archivos estáticos debe dirigir `/api` a Rails; el proxy de Vite solo corresponde
al desarrollo. Esta guía describe la ejecución local de la prueba técnica.
