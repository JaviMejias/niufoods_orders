import assert from 'node:assert/strict'
import { afterEach, mock, test } from 'node:test'
import { fetchOrderDetail, fetchOrdersPage, mergeOrders } from '../src/lib/orders.js'

afterEach(() => mock.restoreAll())

function pageResponse(page, totalCount) {
  const firstIndex = (page - 1) * 20
  const length = Math.max(0, Math.min(20, totalCount - firstIndex))

  return Response.json({
    data: Array.from({ length }, (_, index) => ({ id: totalCount - firstIndex - index })),
    pagination: { page, per_page: 20, total_count: totalCount },
  })
}

test('loads all 100 orders through five pages and stops after a full final page', async () => {
  const requests = []
  mock.method(globalThis, 'fetch', async (url) => {
    requests.push(url)
    const params = new URL(url, 'http://localhost').searchParams
    assert.equal(params.get('per_page'), '20')
    return pageResponse(Number(params.get('page')), 100)
  })

  let page = 1
  let orders = []
  let hasMore = true

  while (hasMore) {
    const result = await fetchOrdersPage(page)
    orders = mergeOrders(orders, result.orders)
    page = result.nextPage
    hasMore = result.hasMore
  }

  assert.equal(requests.length, 5)
  assert.deepEqual(orders.map(({ id }) => id), Array.from({ length: 100 }, (_, i) => 100 - i))
})

test('stops at the short fourth page when there are 63 orders', async () => {
  mock.method(globalThis, 'fetch', async () => pageResponse(4, 63))

  const result = await fetchOrdersPage(4)

  assert.deepEqual(result.orders.map(({ id }) => id), [3, 2, 1])
  assert.equal(result.totalCount, 63)
  assert.equal(result.hasMore, false)
})

test('an empty listing does not request more pages', async () => {
  mock.method(globalThis, 'fetch', async () => pageResponse(1, 0))

  const result = await fetchOrdersPage(1)

  assert.deepEqual(result.orders, [])
  assert.equal(result.hasMore, false)
})

test('overlapping pages keep each ID once and update its data without reordering', () => {
  const previous = [{ id: 3, dispatch_status: 'pending' }, { id: 2 }]
  const next = [{ id: 3, dispatch_status: 'sent' }, { id: 1 }]

  const merged = mergeOrders(previous, next)

  assert.deepEqual(merged, [{ id: 3, dispatch_status: 'sent' }, { id: 2 }, { id: 1 }])
  assert.equal(previous[0].dispatch_status, 'pending')
})

test('a failed page can be retried without discarding the existing orders', async () => {
  let attempts = 0
  mock.method(globalThis, 'fetch', async (url) => {
    assert.equal(new URL(url, 'http://localhost').searchParams.get('page'), '2')
    attempts += 1
    return attempts === 1 ? new Response(null, { status: 503 }) : pageResponse(2, 40)
  })
  const previous = Array.from({ length: 20 }, (_, i) => ({ id: 40 - i }))

  await assert.rejects(fetchOrdersPage(2), /No se pudieron cargar/)
  assert.equal(previous.length, 20)
  const retry = await fetchOrdersPage(2)
  const merged = mergeOrders(previous, retry.orders)

  assert.equal(merged.length, 40)
  assert.equal(retry.hasMore, false)
  assert.equal(attempts, 2)
})

test('passes the abort signal to fetch so unmounted requests can be cancelled', async () => {
  const controller = new AbortController()
  mock.method(globalThis, 'fetch', async (_url, options) => {
    assert.equal(options.signal, controller.signal)
    options.signal.throwIfAborted()
    return pageResponse(1, 20)
  })
  controller.abort()

  await assert.rejects(fetchOrdersPage(1, controller.signal), { name: 'AbortError' })
})

test('rejects unexpected page metadata instead of skipping orders', async () => {
  mock.method(globalThis, 'fetch', async () => pageResponse(3, 100))

  await assert.rejects(fetchOrdersPage(2), /respuesta.*no es válida/)
})

const orderDetail = {
  id: 72,
  restaurant: { id: 3, code: 'NUNO', name: 'Niu Foods Ñuñoa' },
  customer: { name: 'Ana Pérez', phone: '+56912345678' },
  order_type: 'delivery',
  delivery_address: 'Av. Providencia 123',
  dispatch_status: 'sent',
  created_at: '2026-10-01T13:54:11.841Z',
  total_clp: 17980,
  items: [{
    id: 101,
    product: { id: 1, name: 'Niu Roll Salmón', sku: 'NIU-001' },
    quantity: 2,
    unit_price_clp: 8990,
    item_total_clp: 17980,
  }],
}

test('fetches only the selected order and keeps its stored prices and customer data', async () => {
  mock.method(globalThis, 'fetch', async (url) => {
    assert.equal(url, '/api/v1/orders/72')
    return Response.json(orderDetail)
  })

  assert.deepEqual(await fetchOrderDetail(72), orderDetail)
})

test('reports when a selected order no longer exists', async () => {
  mock.method(globalThis, 'fetch', async () => new Response(null, { status: 404 }))

  await assert.rejects(fetchOrderDetail(72), /orden ya no está disponible/)
})

test('allows retrying a failed detail request', async () => {
  let attempts = 0
  mock.method(globalThis, 'fetch', async () => {
    attempts += 1
    return attempts === 1 ? new Response(null, { status: 503 }) : Response.json(orderDetail)
  })

  await assert.rejects(fetchOrderDetail(72), /No se pudo cargar el pedido/)
  assert.deepEqual(await fetchOrderDetail(72), orderDetail)
  assert.equal(attempts, 2)
})

test('cancels the detail request with the provided abort signal', async () => {
  const controller = new AbortController()
  mock.method(globalThis, 'fetch', async (_url, options) => {
    assert.equal(options.signal, controller.signal)
    options.signal.throwIfAborted()
    return Response.json(orderDetail)
  })
  controller.abort()

  await assert.rejects(fetchOrderDetail(72, controller.signal), { name: 'AbortError' })
})

test('rejects a detail response that belongs to another order or lacks items', async () => {
  mock.method(globalThis, 'fetch', async () => Response.json({ ...orderDetail, id: 71 }))
  await assert.rejects(fetchOrderDetail(72), /detalle.*no es válida/)

  mock.method(globalThis, 'fetch', async () => Response.json({ ...orderDetail, items: [] }))
  await assert.rejects(fetchOrderDetail(72), /detalle.*no es válida/)
})
