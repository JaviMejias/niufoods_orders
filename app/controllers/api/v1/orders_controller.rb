module Api
  module V1
    class OrdersController < ApplicationController
      wrap_parameters :order, include: %i[
        restaurant_id order_type delivery_address customer items
      ]

      def index
        orders = Order.dashboard_listing
                      .limit(per_page)
                      .offset((page - 1) * per_page)

        data = orders.map do |order|
          OrderDashboardSerializer.new(order).as_json
        end

        render json: {
          data: data,
          pagination: {
            page: page,
            per_page: per_page,
            total_count: Order.count
          }
        }
      end

      def create
        attributes = order_params.to_h.deep_symbolize_keys
        customer_data = attributes.delete(:customer)
        items = attributes.delete(:items)

        order = Order.new(attributes)
        order.assign_customer_data(customer_data)
        order.order_items_attributes = items if items.present?
        order.calculate_order_total

        if order.save
          OrderDispatcher.new(order).call

          render json: {
            id: order.id,
            status: "created",
            dispatch_status: order.dispatch_status,
            message: "Orden #{order.id} creada."
          }, status: :created
        else
          render json: {
            errors: order.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def order_params
        params.expect(order: [
          :restaurant_id, :order_type, :delivery_address,
          { customer: [:name, :phone] },
          { items: [[ :product_id, :quantity ]] }
        ])
      end

      def page
        [params.fetch(:page, "1").to_i, 1].max
      end

      def per_page
        requested = params.fetch(:per_page, "20").to_i
        return 20 unless requested.positive?

        [requested, 100].min
      end
    end
  end
end