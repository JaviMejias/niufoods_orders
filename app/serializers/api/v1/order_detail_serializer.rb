module Api
  module V1
    class OrderDetailSerializer
      def initialize(order)
        @order = order
      end

      def as_json
        OrderDashboardSerializer.new(@order).as_json.merge(
          customer: {
            name: @order.customer_name,
            phone: @order.customer_phone
          },
          delivery_address: @order.delivery_address,
          items: @order.order_items.map do |item|
            {
              id: item.id,
              product: item.product.as_json(only: %i[id sku name]),
              quantity: item.quantity,
              unit_price_clp: item.unit_price_clp,
              item_total_clp: item.item_total
            }
          end
        )
      end
    end
  end
end
