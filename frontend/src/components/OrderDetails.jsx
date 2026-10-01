import { useEffect, useState } from 'react'
import { fetchOrderDetail } from '../lib/orders.js'
import { currencyFormatter, dateFormatter, dispatchStatusLabels } from '../lib/formatters.js'
import './OrderDetails.css'

export default function OrderDetails({ orderId }) {
  const [detail, setDetail] = useState({ loading: true, error: '', order: null })
  const [attempt, setAttempt] = useState(0)

  useEffect(() => {
    const controller = new AbortController()

    async function loadDetail() {
      try {
        const order = await fetchOrderDetail(orderId, controller.signal)
        if (!controller.signal.aborted) setDetail({ loading: false, error: '', order })
      } catch (error) {
        if (!controller.signal.aborted) {
          setDetail({
            loading: false,
            error: error instanceof TypeError
              ? 'No se pudo conectar con el servidor. Intenta nuevamente.'
              : error.message,
            order: null,
          })
        }
      }
    }

    loadDetail()
    return () => controller.abort()
  }, [orderId, attempt])

  if (detail.loading) {
    return (
      <div className="detail-message" role="status">
        <span className="loading-indicator" aria-hidden="true" />
        <p>Cargando pedido…</p>
      </div>
    )
  }

  if (detail.error) {
    return (
      <div className="detail-message detail-message--error" role="alert">
        <p>{detail.error}</p>
        <button
          className="load-more-button"
          type="button"
          onClick={() => {
            setDetail({ loading: true, error: '', order: null })
            setAttempt((previous) => previous + 1)
          }}
        >
          Reintentar
        </button>
      </div>
    )
  }

  const { order } = detail

  return (
    <div className="order-detail">
      <section className="detail-summary" aria-label="Resumen del pedido">
        <div>
          <h3>{order.restaurant.name}</h3>
          <p>
            {order.order_type === 'pickup' ? 'Retiro en restaurante' : 'Entrega a domicilio'}
            {' · '}
            <time dateTime={order.created_at}>
              {dateFormatter.format(new Date(order.created_at))}
            </time>
          </p>
        </div>
        <span className={`dispatch-badge dispatch-badge--${order.dispatch_status}`}>
          {dispatchStatusLabels[order.dispatch_status] ?? 'Estado desconocido'}
        </span>
      </section>

      <section className="detail-customer" aria-labelledby={`customer-heading-${order.id}`}>
        <h3 id={`customer-heading-${order.id}`}>Datos del cliente</h3>
        <dl>
          <div>
            <dt>Nombre</dt>
            <dd>{order.customer.name}</dd>
          </div>
          <div>
            <dt>Teléfono</dt>
            <dd>{order.customer.phone}</dd>
          </div>
          {order.order_type === 'delivery' && (
            <div className="detail-customer__address">
              <dt>Dirección de entrega</dt>
              <dd>{order.delivery_address}</dd>
            </div>
          )}
        </dl>
      </section>

      <section className="detail-products" aria-labelledby={`products-heading-${order.id}`}>
        <h3 id={`products-heading-${order.id}`}>Productos del pedido</h3>
        <p className="detail-products__hint">Desplaza la tabla para ver los montos.</p>
        <div className="detail-products__scroll" role="region" aria-label="Productos del pedido" tabIndex={0}>
          <table className="detail-products__table">
            <caption className="visually-hidden">Productos, cantidades y precios en pesos chilenos</caption>
            <thead>
              <tr>
                <th scope="col">Producto</th>
                <th scope="col" className="detail-products__quantity">Cant.</th>
                <th scope="col" className="amount-cell">Precio unitario</th>
                <th scope="col" className="amount-cell">Subtotal</th>
              </tr>
            </thead>
            <tbody>
              {order.items.map((item) => (
                <tr key={item.id}>
                  <td>
                    <strong>{item.product.name}</strong>
                    <span className="detail-products__sku">{item.product.sku}</span>
                  </td>
                  <td className="detail-products__quantity">{item.quantity}</td>
                  <td className="amount-cell">{currencyFormatter.format(item.unit_price_clp)}</td>
                  <td className="amount-cell">{currencyFormatter.format(item.item_total_clp)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
        <div className="detail-total">
          <span>Total del pedido <small>CLP</small></span>
          <strong>{currencyFormatter.format(order.total_clp)}</strong>
        </div>
      </section>
    </div>
  )
}
