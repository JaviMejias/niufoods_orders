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
