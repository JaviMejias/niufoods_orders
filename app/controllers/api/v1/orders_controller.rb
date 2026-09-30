module Api
  module V1
    class OrdersController < ApplicationController
      wrap_parameters :order, include: %i[
        restaurant_id order_type delivery_address customer items
      ]

      def create
        attributes = order_params.to_h.deep_symbolize_keys
        customer_data = attributes.delete(:customer)
        items = attributes.delete(:items)

        order = Order.new(attributes)
        order.assign_customer_data(customer_data)
        order.order_items_attributes = items if items.present?
        order.calculate_order_total

        if order.save
          render json: {
            id: order.id,status: "created", message: "Orden #{order.id} creada."
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
    end
  end
end