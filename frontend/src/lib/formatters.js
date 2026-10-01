export const currencyFormatter = new Intl.NumberFormat('es-CL', {
  style: 'currency',
  currency: 'CLP',
})

export const dateFormatter = new Intl.DateTimeFormat('es-CL', {
  dateStyle: 'short',
  timeStyle: 'short',
  timeZone: 'America/Santiago',
})

export const dispatchStatusLabels = {
  pending: 'Pendiente de envío',
  sent: 'Enviada al restaurante',
  error: 'Error de envío',
}
