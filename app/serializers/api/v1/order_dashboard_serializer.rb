module Api
  module V1
    class OrderDashboardSerializer
      def initialize(order)
        @order = order
      end

      def as_json
        {
          id: @order.id,
          restaurant: @order.restaurant.as_json(only: %i[id code name]),
          total_clp: @order.total_clp,
          order_type: @order.order_type,
          created_at: @order.created_at,
          dispatch_status: @order.dispatch_status
        }
      end
    end
  end
end