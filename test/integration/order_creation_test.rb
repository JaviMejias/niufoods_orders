require "test_helper"
require "net/http"

class OrderCreationTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @restaurant = Restaurant.create!(name: "Niu Foods Providencia", code: "TEST-PROV")
    @product = Product.create!(name: "Niu Roll Salmón", sku: "TEST-SKU-001", price_clp: 8990)
    @payload = {
      restaurant_id: @restaurant.id,
      order_type: "pickup",
      customer: { name: "Ana Pérez", phone: "+56912345678" },
      items: [ { product_id: @product.id, quantity: 2 } ]
    }
  end

  test "calculates and persists the total from product prices and quantities" do
    payload = order_payload_with_multiple_products

    with_successful_dispatch do
      assert_difference "Order.count", 1 do
        assert_difference "OrderItem.count", 2 do
          post api_v1_orders_url, params: payload, as: :json
        end
      end
    end

    assert_response :created
    assert_equal "sent", response.parsed_body.fetch("dispatch_status")

    order = Order.find(response.parsed_body.fetch("id"))
    items = order.order_items.order(:product_id).to_a
    assert_equal 22470, order.total_clp
    assert_equal [ 2, 1 ], items.map(&:quantity)
    assert_equal [ 8990, 4490 ], items.map(&:unit_price_clp)
    assert_equal [ 17980, 4490 ], items.map(&:item_total)
  end

  test "ignores totals and unit prices supplied by the client" do
    payload = order_payload_with_multiple_products.merge(total_clp: 1)
    payload[:items].each { |item| item[:unit_price_clp] = 1 }

    with_successful_dispatch do
      post api_v1_orders_url, params: payload, as: :json
    end

    assert_response :created

    order = Order.find(response.parsed_body.fetch("id"))
    assert_equal 22470, order.total_clp
    assert_equal [ 8990, 4490 ], order.order_items.order(:product_id).pluck(:unit_price_clp)
  end

  test "rejects an unknown order type without saving the order or its items" do
    assert_no_difference [ "Order.count", "OrderItem.count" ] do
      post api_v1_orders_url, params: @payload.merge(order_type: "invalid"), as: :json
    end

    assert_response :unprocessable_entity
    assert_equal [ "Order type is not included in the list" ], response.parsed_body.fetch("errors")
  end

  test "records a dispatch error when the store closes the connection unexpectedly" do
    assert_failed_dispatch EOFError.new("end of file reached")
  end

  test "records a dispatch error when the connection stream is closed" do
    assert_failed_dispatch IOError.new("stream closed in another thread")
  end

  private

  def order_payload_with_multiple_products
    product = Product.create!(name: "Gyozas de Pollo x5", sku: "TEST-SKU-005", price_clp: 4490)
    @payload.merge(items: [
      { product_id: @product.id, quantity: 2 },
      { product_id: product.id, quantity: 1 }
    ])
  end

  def with_successful_dispatch
    simulated_http = Class.new(Net::HTTP)
    simulated_http.define_singleton_method(:start) do |*, **, &block|
      connection = Object.new
      connection.define_singleton_method(:request) do |request|
        payload = JSON.parse(request.body)
        acknowledgment = {
          status: "received",
          order_id: payload.fetch("order_id"),
          restaurant_id: payload.dig("restaurant", "id")
        }
        result = Net::HTTPCreated.new("1.1", "201", "Created")
        result.define_singleton_method(:body) { acknowledgment.to_json }
        result
      end
      block.call(connection)
    end

    stub_const(Net, :HTTP, simulated_http) { yield }
  end

  def assert_failed_dispatch(connection_error)
    failing_http = Class.new(Net::HTTP)
    failing_http.define_singleton_method(:start) do |*, **|
      raise connection_error
    end

    stub_const(Net, :HTTP, failing_http) do
      assert_difference [ "Order.count", "OrderItem.count" ], 1 do
        post api_v1_orders_url, params: @payload, as: :json
      end
    end

    assert_response :created
    assert_equal "created", response.parsed_body.fetch("status")
    assert_equal "error", response.parsed_body.fetch("dispatch_status")

    order = Order.find(response.parsed_body.fetch("id"))
    assert order.error?
    assert_equal "No se pudo completar el despacho: #{connection_error.message}", order.dispatch_error
    assert_nil order.dispatched_at
    assert_equal 2, order.order_items.sole.quantity
  end
end
