require "test_helper"

class OrderDetailTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @restaurant = Restaurant.create!(name: "Niu Foods Providencia", code: "TEST-DETAIL")
    @product = Product.create!(name: "Niu Roll Salmón", sku: "TEST-DETAIL-001", price_clp: 8990)
    @second_product = Product.create!(name: "Gyozas", sku: "TEST-DETAIL-002", price_clp: 4990)
    @order = Order.new(
      restaurant: @restaurant, customer_name: "Ana Pérez", customer_phone: "+56912345678",
      order_type: "delivery", delivery_address: "Av. Providencia 123", dispatch_status: "sent"
    )
    @order.order_items.build(product: @product, quantity: 2)
    @order.order_items.build(product: @second_product, quantity: 1)
    @order.calculate_order_total
    @order.save!
  end

  test "returns customer, restaurant and all items with the stored prices" do
    @product.update!(price_clp: 12990)

    assert_no_difference [ "Order.count", "OrderItem.count" ] do
      get api_v1_order_url(@order), as: :json
    end

    assert_response :ok
    detail = response.parsed_body
    assert_equal @order.id, detail.fetch("id")
    assert_equal @restaurant.as_json(only: %i[id code name]), detail.fetch("restaurant")
    assert_equal({ "name" => "Ana Pérez", "phone" => "+56912345678" }, detail.fetch("customer"))
    assert_equal "Av. Providencia 123", detail.fetch("delivery_address")
    assert_equal "delivery", detail.fetch("order_type")
    assert_equal "sent", detail.fetch("dispatch_status")
    assert_equal @order.created_at.as_json, detail.fetch("created_at")
    assert_equal 22970, detail.fetch("total_clp")

    items = detail.fetch("items").index_by { |item| item.fetch("product").fetch("id") }
    assert_equal 2, items.size
    first_item = items.fetch(@product.id)
    assert_equal @order.order_items.find_by!(product: @product).id, first_item.fetch("id")
    assert_equal "Niu Roll Salmón", first_item.fetch("product").fetch("name")
    assert_equal "TEST-DETAIL-001", first_item.fetch("product").fetch("sku")
    assert_equal 2, first_item.fetch("quantity")
    assert_equal 8990, first_item.fetch("unit_price_clp")
    assert_equal 17980, first_item.fetch("item_total_clp")
    assert_equal 4990, items.fetch(@second_product.id).fetch("item_total_clp")
    assert_equal detail.fetch("total_clp"), items.values.sum { |item| item.fetch("item_total_clp") }
    assert_equal "sent", @order.reload.dispatch_status
  end

  test "returns a pickup order without a delivery address" do
    @order.update!(order_type: "pickup", delivery_address: nil, dispatch_status: "pending")

    get api_v1_order_url(@order), as: :json

    assert_response :ok
    assert_equal "pickup", response.parsed_body.fetch("order_type")
    assert_equal "pending", response.parsed_body.fetch("dispatch_status")
    assert_nil response.parsed_body.fetch("delivery_address")
  end

  test "returns JSON with status 404 for an unknown order" do
    get api_v1_order_url(id: Order.maximum(:id) + 1), as: :json

    assert_response :not_found
    assert_equal({ "error" => "Orden no encontrada." }, response.parsed_body)
  end

  test "keeps the dashboard listing compact" do
    get api_v1_orders_url, as: :json

    assert_response :ok
    entry = response.parsed_body.fetch("data").find { |order| order.fetch("id") == @order.id }
    assert entry
    assert_equal %w[created_at dispatch_status id order_type restaurant total_clp], entry.keys.sort
  end
end
