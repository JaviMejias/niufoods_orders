require "net/http"
require "json"

class OrderDispatcher
  STORE_BASE_URL = ENV.fetch(
    "STORE_BASE_URL",
    "http://127.0.0.1:3001"
  )

  def initialize(order)
    @order = order
  end

  def call
    store_path = Rails.application.routes.url_helpers
                      .api_v1_store_restaurant_orders_path(@order.restaurant_id)
    uri = URI.join(STORE_BASE_URL, store_path)
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

    if received_by_destination?(acknowledgment)
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

  def received_by_destination?(acknowledgment)
    acknowledgment.is_a?(Hash) &&
      acknowledgment["status"] == "received" &&
      acknowledgment["order_id"].to_s == @order.id.to_s &&
      acknowledgment["restaurant_id"].to_s == @order.restaurant_id.to_s
  end

  def mark_as_error(message)
    @order.update!(
      dispatch_status: :error,
      dispatch_error: message
    )
  end
end
