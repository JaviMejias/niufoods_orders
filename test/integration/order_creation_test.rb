require "test_helper"

class OrderCreationTest < ActionDispatch::IntegrationTest
  self.fixture_table_names = []

  setup do
    @restaurant = Restaurant.create!(name: "Niu Foods Providencia", code: "TEST-PROV")
    @product = Product.create!(name: "Niu Roll Salmón", sku: "TEST-SKU-001", price_clp: 8990)
  end

  test "rejects an unknown order type without saving the order or its items" do
    payload = {
      restaurant_id: @restaurant.id,
      order_type: "invalid",
      customer: { name: "Ana Pérez", phone: "+56912345678" },
      items: [ { product_id: @product.id, quantity: 2 } ]
    }

    assert_no_difference [ "Order.count", "OrderItem.count" ] do
      post api_v1_orders_url, params: payload, as: :json
    end

    assert_response :unprocessable_entity
    assert_equal [ "Order type is not included in the list" ], response.parsed_body.fetch("errors")
  end
end
