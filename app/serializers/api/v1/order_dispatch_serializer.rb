module Api
  module V1
    class OrderDispatchSerializer
      def initialize(order)
        @order = order
      end

      def as_json
        {
          order_id: @order.id,
          restaurant: @order.restaurant.as_json(only: %i[id code name]),
          customer: {
            name: @order.customer_name,
            phone: @order.customer_phone
          },
          order_type: @order.order_type,
          delivery_address: @order.delivery_address,
          items: @order.order_items.map do |item|
            item.as_json(only: %i[quantity unit_price_clp]).merge(
              product: item.product.as_json(only: %i[sku name])
            )
          end,
          total_clp: @order.total_clp
        }
      end
    end
  end
end
