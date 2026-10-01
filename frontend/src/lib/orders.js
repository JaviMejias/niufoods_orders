export const ORDERS_PER_PAGE = 20

export async function fetchOrdersPage(page, signal) {
  const response = await fetch(
    `/api/v1/orders?page=${page}&per_page=${ORDERS_PER_PAGE}`,
    { signal },
  )

  if (!response.ok) {
    throw new Error('No se pudieron cargar las órdenes.')
  }

  const { data, pagination } = await response.json()

  if (
    !Array.isArray(data) ||
    pagination?.page !== page ||
    !Number.isInteger(pagination.per_page) ||
    pagination.per_page <= 0 ||
    !Number.isInteger(pagination.total_count) ||
    pagination.total_count < 0
  ) {
    throw new Error('La respuesta del listado de órdenes no es válida.')
  }

  return {
    orders: data,
    totalCount: pagination.total_count,
    nextPage: pagination.page + 1,
    hasMore: data.length > 0 &&
      pagination.page * pagination.per_page < pagination.total_count,
  }
}

export function mergeOrders(previousOrders, nextOrders) {
  const ordersById = new Map(previousOrders.map((order) => [order.id, order]))

  for (const order of nextOrders) {
    ordersById.set(order.id, order)
  }

  return [...ordersById.values()]
}
