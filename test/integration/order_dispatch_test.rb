require "test_helper"
require "net/http"

class OrderDispatchTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @restaurants = {
      "PROV" => "Niu Foods Providencia",
      "LCON" => "Niu Foods Las Condes",
      "NUNO" => "Niu Foods Ñuñoa"
    }.each_with_object({}) do |(code, name), restaurants|
      restaurants[code] = Restaurant.find_or_create_by!(code: code) do |restaurant|
        restaurant.name = name
      end
    end
    @product = Product.create!(name: "Niu Roll Salmón", sku: "TEST-DISPATCH-SKU", price_clp: 8990)
  end

  %w[PROV LCON NUNO].each do |code|
    test "dispatches an order to #{code} and confirms its receipt" do
      restaurant = @restaurants.fetch(code)
      receiver = ActionDispatch::Integration::Session.new(Rails.application)
      dispatched_path = nil
      dispatched_payload = nil
      acknowledgment = nil
      handler = lambda do |request|
        dispatched_path = request.path
        dispatched_payload = JSON.parse(request.body)
        receiver.post request.path, params: dispatched_payload, as: :json
        acknowledgment = receiver.response.parsed_body
        http_response(receiver.response.status, acknowledgment)
      end

      with_store_http(handler) do
        assert_difference [ "Order.count", "OrderItem.count" ], 1 do
          post api_v1_orders_url, params: order_payload(restaurant), as: :json
        end
      end

      assert_response :created
      assert_equal "/api/v1/store/restaurants/#{restaurant.id}/orders", dispatched_path
      assert_equal restaurant.id, dispatched_payload.dig("restaurant", "id")
      assert_equal code, dispatched_payload.dig("restaurant", "code")
      assert_equal restaurant.id, acknowledgment.fetch("restaurant_id")
      assert_equal response.parsed_body.fetch("id"), acknowledgment.fetch("order_id")
      assert_equal "sent", response.parsed_body.fetch("dispatch_status")

      order = Order.find(response.parsed_body.fetch("id"))
      assert order.sent?
      assert_not_nil order.dispatched_at
      assert_nil order.dispatch_error
    end
  end

  test "rejects an order delivered to a different restaurant" do
    destination = @restaurants.fetch("PROV")
    payload = receipt_payload(@restaurants.fetch("LCON"))

    post store_orders_path(destination), params: payload, as: :json

    assert_response :unprocessable_entity
    assert_equal "error", response.parsed_body.fetch("status")
    assert_equal "La orden no corresponde a esta tienda.", response.parsed_body.fetch("message")
  end

  test "rejects a receipt without restaurant data" do
    post store_orders_path(@restaurants.fetch("PROV")), params: { order_id: 123 }, as: :json

    assert_response :unprocessable_entity
    assert_equal "error", response.parsed_body.fetch("status")
  end

  test "rejects a receipt without an order id" do
    restaurant = @restaurants.fetch("PROV")
    payload = receipt_payload(restaurant).except(:order_id)

    post store_orders_path(restaurant), params: payload, as: :json

    assert_response :unprocessable_entity
    assert_equal "Falta order_id", response.parsed_body.fetch("message")
  end

  test "returns not found for an unknown destination restaurant" do
    post "/api/v1/store/restaurants/999999999/orders",
         params: receipt_payload(@restaurants.fetch("PROV")), as: :json

    assert_response :not_found
    assert_equal "error", response.parsed_body.fetch("status")
  end

  %w[restaurant_id order_id].each do |field|
    test "records an error when the store confirms a different #{field}" do
      restaurant = @restaurants.fetch("PROV")
      handler = lambda do |request|
        payload = JSON.parse(request.body)
        acknowledgment = {
          "status" => "received",
          "order_id" => payload.fetch("order_id"),
          "restaurant_id" => restaurant.id
        }
        acknowledgment[field] += 1
        http_response(201, acknowledgment)
      end

      with_store_http(handler) do
        post api_v1_orders_url, params: order_payload(restaurant), as: :json
      end

      assert_response :created
      assert_equal "error", response.parsed_body.fetch("dispatch_status")
      order = Order.find(response.parsed_body.fetch("id"))
      assert order.error?
      assert_not_nil order.dispatch_error
      assert_nil order.dispatched_at
    end
  end

  private

  def order_payload(restaurant)
    {
      restaurant_id: restaurant.id,
      order_type: "pickup",
      customer: { name: "Ana Pérez", phone: "+56912345678" },
      items: [ { product_id: @product.id, quantity: 2 } ]
    }
  end

  def receipt_payload(restaurant)
    {
      order_id: 123,
      restaurant: { id: restaurant.id, code: restaurant.code, name: restaurant.name }
    }
  end

  def store_orders_path(restaurant)
    "/api/v1/store/restaurants/#{restaurant.id}/orders"
  end

  def http_response(status, body)
    response_class = Net::HTTPResponse::CODE_TO_OBJ.fetch(status.to_s)
    result = response_class.new("1.1", status.to_s, "Store response")
    result.define_singleton_method(:body) { body.to_json }
    result
  end

  def with_store_http(handler)
    simulated_http = Class.new(Net::HTTP)
    simulated_http.define_singleton_method(:start) do |*, **, &block|
      connection = Object.new
      connection.define_singleton_method(:request) { |request| handler.call(request) }
      block.call(connection)
    end

    stub_const(Net, :HTTP, simulated_http) { yield }
  end
end
