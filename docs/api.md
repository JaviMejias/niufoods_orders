# API de órdenes

Dirección local de la API central: `http://127.0.0.1:3000`.
Enviar JSON con `Content-Type: application/json` y solicitar las respuestas con
`Accept: application/json`.

Los ejemplos utilizan los IDs del catálogo en una base recién creada. Los IDs de
órdenes, ítems y las fechas de respuesta son ilustrativos. Si ya existen datos,
usar los IDs reales indicados en el [README](../README.md#ejemplos-de-api).

## Endpoints

| Método | Ruta | Resultado |
| --- | --- | --- |
| POST | `/api/v1/orders` | Crear y despachar una orden |
| GET | `/api/v1/orders` | Consultar el listado paginado |
| GET | `/api/v1/orders/:id` | Consultar el detalle de una orden |
| POST | `/api/v1/store/restaurants/:restaurant_id/orders` | Confirmar recepción en la tienda simulada, puerto 3001 |

## Crear una orden

`POST /api/v1/orders`

```json
{
  "restaurant_id": 2,
  "order_type": "delivery",
  "customer": {
    "name": "Ana Pérez",
    "phone": "+56912345678"
  },
  "delivery_address": "Av. Providencia 1234, Santiago",
  "items": [
    { "product_id": 1, "quantity": 2 },
    { "product_id": 5, "quantity": 1 }
  ]
}
```

| Campo | Requisito |
| --- | --- |
| `restaurant_id` | Restaurante existente |
| `order_type` | `pickup` o `delivery` |
| `customer.name` | Nombre no vacío |
| `customer.phone` | Teléfono no vacío |
| `delivery_address` | Obligatorio para `delivery`; opcional para `pickup` |
| `items` | Al menos un ítem |
| `items[].product_id` | Producto existente |
| `items[].quantity` | Número entero mayor que cero |

Para retiro, utilizar `order_type: "pickup"` y omitir la dirección. No se exige un
formato específico del teléfono, solo su presencia. No enviar precios unitarios
ni un total: Rails toma los precios del catálogo. Con los seeds, el ejemplo suma
`2 × 8990 + 1 × 4490 = 22470` CLP.

### Respuesta de creación: HTTP 201

```json
{
  "id": 1,
  "status": "created",
  "dispatch_status": "sent",
  "message": "Orden 1 creada."
}
```

Si el pedido se guarda pero el envío falla, la respuesta sigue siendo HTTP 201 y
`dispatch_status` es `error`. El error de despacho se guarda en la orden; no se
incluye su descripción interna en el listado ni en el detalle público.

### Errores de validación: HTTP 422

Por ejemplo, al enviar `customer.name: ""`:

```json
{
  "errors": ["Customer name can't be blank"]
}
```

Los mensajes de validación utilizan el idioma predeterminado de Rails, inglés.
El dashboard presenta sus etiquetas y mensajes en español. Restaurante/producto
inexistente, modalidad no admitida, cantidad inválida, ausencia de ítems o dirección
faltante para delivery también producen errores de validación. Un cuerpo que no
cumple la estructura esperada por los strong params puede responder HTTP 400.

## Listar órdenes

`GET /api/v1/orders?page=1&per_page=20`

| Parámetro | Comportamiento |
| --- | --- |
| `page` | Predeterminado 1; valores menores que 1 se ajustan a 1 |
| `per_page` | Predeterminado 20; valores no positivos usan 20; máximo 100 |

La respuesta se ordena por fecha de creación descendente y luego por ID descendente.
Una página sin registros devuelve `data: []` y mantiene los metadatos.

Ejemplo con una única orden guardada, HTTP 200:

```json
{
  "data": [
    {
      "id": 1,
      "restaurant": { "id": 2, "code": "LCON", "name": "Niu Foods Las Condes" },
      "total_clp": 22470,
      "order_type": "delivery",
      "created_at": "2026-10-01T13:00:00.000Z",
      "dispatch_status": "sent"
    }
  ],
  "pagination": { "page": 1, "per_page": 20, "total_count": 1 }
}
```

El listado incluye solo la información operacional principal. El frontend utiliza
`pagination` para solicitar más páginas. Los valores `pending`, `sent` y `error`
describen el despacho a la tienda; no representan la preparación o entrega al cliente.

## Consultar el detalle

`GET /api/v1/orders/1`

HTTP 200:

```json
{
  "id": 1,
  "restaurant": { "id": 2, "code": "LCON", "name": "Niu Foods Las Condes" },
  "total_clp": 22470,
  "order_type": "delivery",
  "created_at": "2026-10-01T13:00:00.000Z",
  "dispatch_status": "sent",
  "customer": { "name": "Ana Pérez", "phone": "+56912345678" },
  "delivery_address": "Av. Providencia 1234, Santiago",
  "items": [
    {
      "id": 1,
      "product": { "id": 1, "sku": "SKU-001", "name": "Niu Roll Salmón" },
      "quantity": 2,
      "unit_price_clp": 8990,
      "item_total_clp": 17980
    },
    {
      "id": 2,
      "product": { "id": 5, "sku": "SKU-005", "name": "Gyozas de Pollo x5" },
      "quantity": 1,
      "unit_price_clp": 4490,
      "item_total_clp": 4490
    }
  ]
}
```

Los precios unitarios y el total pertenecen a la orden guardada. La dirección puede
ser `null` en pedidos de retiro. Las fechas se envían como ISO 8601 en UTC; el
dashboard las presenta en `America/Santiago`. Listar o consultar no modifica ni
vuelve a despachar el pedido.

Si el ID no existe, HTTP 404:

```json
{ "error": "Orden no encontrada." }
```

## Recepción de tienda

Con la configuración local, `OrderDispatcher` envía al puerto 3001 un payload con
`order_id`, `restaurant` (ID, código y nombre), cliente, modalidad, dirección,
ítems con SKU/nombre, cantidades, precios unitarios y total. El ID del restaurante
también va en la ruta.

El receptor exige `order_id` y comprueba que el ID y código del restaurante del
payload coincidan con la ruta. Devuelve HTTP 201:

```json
{ "status": "received", "order_id": 1, "restaurant_id": 2 }
```

Una tienda inexistente responde HTTP 404. Un `order_id` ausente o un restaurante
que no corresponde a la ruta responde HTTP 422, con `status: "error"` y `message`.
No valida el pedido completo ni comprueba que `order_id` exista: es un receptor
simulado de confirmación del destino. Ver [la guía de simulación](store_simulation.md).
