require "net/http"
require "json"

class OrderDispatcher
  STORE_URL = ENV.fetch(
    "STORE_ORDERS_URL",
    "http://127.0.0.1:3001/api/v1/store/orders"
  )

  def initialize(order)
    @order = order
  end

  def call
    uri = URI(STORE_URL)
    request = Net::HTTP::Post.new(uri)
    request["Content-Type"] = "application/json"
    request["Accept"] = "application/json"
    payload = Api::V1::OrderDispatchSerializer.new(@order).as_json
    request.body = payload.to_json

    response = Net::HTTP.start(
      uri.hostname,
      uri.port,
      use_ssl: uri.scheme == "https",
      open_timeout: 2,
      read_timeout: 5
    ) do |http|
      http.request(request)
    end

    acknowledgment =
      response.is_a?(Net::HTTPSuccess) ? JSON.parse(response.body) : {}

    if acknowledgment["status"] == "received"
      @order.update!(
        dispatch_status: :sent,
        dispatched_at: Time.current,
        dispatch_error: nil
      )
    else
      mark_as_error("El local no confirmó la recepción (HTTP #{response.code}).")
    end
  rescue Net::OpenTimeout, Net::ReadTimeout, SocketError,
         SystemCallError, IOError, JSON::ParserError => error
    mark_as_error("No se pudo completar el despacho: #{error.message}")
  end

  private

  def mark_as_error(message)
    @order.update!(
      dispatch_status: :error,
      dispatch_error: message
    )
  end
end
