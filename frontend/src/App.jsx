import { useCallback, useEffect, useRef, useState } from 'react'
import { fetchOrdersPage, mergeOrders } from './lib/orders.js'
import './App.css'

const currencyFormatter = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
})

const dateFormatter = new Intl.DateTimeFormat('es-CL', {
  dateStyle: 'short',
  timeStyle: 'short',
  timeZone: 'America/Santiago',
})

const dispatchStatusLabels = {
  pending: 'Pendiente de envío',
  sent: 'Enviada al restaurante',
  error: 'Error de envío',
}

function App() {
  const [feed, setFeed] = useState({
    orders: [],
    loading: true,
    error: '',
    totalCount: 0,
    hasMore: true,
    nextPage: 1,
  })
  const [request, setRequest] = useState({ page: 1 })
  const requestInFlight = useRef(true)
  const loadMoreTarget = useRef(null)
  const { orders, loading, error, totalCount, hasMore, nextPage } = feed
  const initialLoading = loading && orders.length === 0
  const initialError = error && orders.length === 0

  useEffect(() => {
    const controller = new AbortController()

    async function loadOrders() {
      try {
        const result = await fetchOrdersPage(request.page, controller.signal)

        if (!controller.signal.aborted) {
          setFeed((previous) => ({
            ...result,
            orders: mergeOrders(previous.orders, result.orders),
            loading: false,
            error: '',
          }))
        }
      } catch {
        if (!controller.signal.aborted) {
          setFeed((previous) => ({
            ...previous,
            loading: false,
            error: previous.orders.length > 0
              ? 'No se pudieron cargar más órdenes. Intenta nuevamente.'
              : 'No se pudieron cargar las órdenes. Intenta nuevamente.',
          }))
        }
      } finally {
        if (!controller.signal.aborted) {
          requestInFlight.current = false
        }
      }
    }

    loadOrders()

    return () => controller.abort()
  }, [request])

  const loadMore = useCallback(() => {
    if (requestInFlight.current || !hasMore) return

    requestInFlight.current = true
    setFeed((previous) => ({ ...previous, loading: true, error: '' }))
    setRequest({ page: nextPage })
  }, [hasMore, nextPage])

  useEffect(() => {
    if (loading || error || !hasMore || !loadMoreTarget.current) return
    if (typeof IntersectionObserver === 'undefined') return

    let active = true
    const observer = new IntersectionObserver(
      (entries) => {
        if (active && entries.some((entry) => entry.isIntersecting)) loadMore()
      },
      { rootMargin: '0px 0px 240px 0px' },
    )

    observer.observe(loadMoreTarget.current)

    return () => {
      active = false
      observer.disconnect()
    }
  }, [loading, error, hasMore, loadMore])

  return (
    <div className="app-shell">
      <header className="app-header">
        <div className="app-header__inner">
          <div className="brand">
            <span className="brand__mark" aria-hidden="true">niu</span>
            <span className="brand__name">Niu Foods</span>
          </div>
          <span className="app-header__label">Panel de órdenes</span>
          <span className="app-header__locale">Chile · CLP</span>
        </div>
      </header>

      <main className="dashboard">
        <div className="page-heading">
          <div>
            <p className="page-heading__eyebrow">Gestión de restaurantes</p>
            <h1>Órdenes</h1>
            <p className="page-heading__description">
              Consulta los pedidos recibidos y su estado de envío.
            </p>
          </div>
          <div className="page-heading__timezone">
            <span>Zona horaria</span>
            <strong>Santiago, Chile</strong>
          </div>
        </div>

        <section className="orders-panel" aria-labelledby="orders-heading">
          <div className="orders-panel__header">
            <div>
              <h2 id="orders-heading">Pedidos recibidos</h2>
              <p>Información de cada orden y su restaurante.</p>
            </div>
            {!initialLoading && !initialError && (
              <span className="orders-count">
                <strong>{orders.length}</strong> de <strong>{totalCount}</strong> órdenes
              </span>
            )}
          </div>

          {initialLoading && (
            <div className="panel-message" role="status">
              <span className="loading-indicator" aria-hidden="true" />
              <p>Cargando órdenes…</p>
            </div>
          )}

          {initialError && (
            <div className="panel-message panel-message--error" role="alert">
              <span className="message-symbol" aria-hidden="true">!</span>
              <p>{error}</p>
              <button className="load-more-button" type="button" onClick={loadMore}>
                Reintentar
              </button>
            </div>
          )}

          {!initialLoading && !initialError && orders.length === 0 && (
            <div className="panel-message">
              <span className="message-symbol" aria-hidden="true">—</span>
              <h3>Aún no hay órdenes</h3>
              <p>Los nuevos pedidos aparecerán en este listado.</p>
            </div>
          )}

          {orders.length > 0 && (
            <>
              <p className="table-scroll-hint">
                Desplaza la tabla para ver todas las columnas.
              </p>
              <div
                className="table-scroll"
                role="region"
                aria-label="Listado de órdenes"
                tabIndex={0}
              >
                <table className="orders-table" id="orders-table">
                  <caption className="visually-hidden">
                    Órdenes cargadas, desde las más recientes
                  </caption>
                  <thead>
                    <tr>
                      <th scope="col">N.º de orden</th>
                      <th scope="col">Restaurante</th>
                      <th scope="col" className="amount-cell">Total CLP</th>
                      <th scope="col">Modalidad</th>
                      <th scope="col">Fecha de creación</th>
                      <th scope="col">Estado del despacho</th>
                    </tr>
                  </thead>
                  <tbody>
                    {orders.map((order) => (
                      <tr key={order.id}>
                        <td>
                          <span className="order-number">#{order.id}</span>
                        </td>
                        <td className="restaurant-cell">
                          <span className="restaurant-name">{order.restaurant.name}</span>
                          <span className="restaurant-code">{order.restaurant.code}</span>
                        </td>
                        <td className="amount-cell">
                          <span className="order-amount">
                            {currencyFormatter.format(order.total_clp)}
                          </span>
                        </td>
                        <td>
                          <span className={`order-mode order-mode--${order.order_type}`}>
                            {order.order_type === 'pickup' ? 'Retiro' : 'A domicilio'}
                          </span>
                        </td>
                        <td className="date-cell">
                          <time dateTime={order.created_at}>
                            {dateFormatter.format(new Date(order.created_at))}
                          </time>
                        </td>
                        <td>
                          <span className={`dispatch-badge dispatch-badge--${order.dispatch_status}`}>
                            {dispatchStatusLabels[order.dispatch_status] ?? 'Estado desconocido'}
                          </span>
                        </td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>

              <div className="orders-pagination" ref={loadMoreTarget}>
                <div className="orders-pagination__message">
                  {error ? (
                    <p className="pagination-error" role="alert">{error}</p>
                  ) : (
                    <p role="status">
                      {loading
                        ? 'Cargando más órdenes…'
                        : hasMore
                          ? 'Desplázate hacia abajo para ver más órdenes.'
                          : 'Has llegado al final del listado.'}
                    </p>
                  )}
                </div>
                <button
                  className="load-more-button"
                  type="button"
                  onClick={loadMore}
                  disabled={loading || !hasMore}
                  aria-controls="orders-table"
                >
                  {loading && <span className="loading-indicator" aria-hidden="true" />}
                  {loading
                    ? 'Cargando…'
                    : error
                      ? 'Reintentar'
                      : hasMore
                        ? 'Cargar más'
                        : 'Listado completo'}
                </button>
              </div>
            </>
          )}

          <div className="orders-panel__footer">
            <p>El estado indica el envío de la orden al restaurante.</p>
            <span>Montos en CLP · Hora de Chile</span>
          </div>
        </section>
      </main>
    </div>
  )
}

export default App
