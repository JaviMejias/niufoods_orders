module Api
  module V1
    module Store
      class OrdersController < ApplicationController
        def create
          restaurant = Restaurant.find_by(id: params[:restaurant_id])
          payload = params.permit(:order_id, restaurant: [ :id, :code ])

          if restaurant.nil?
            render json: {
              status: "error",
              message: "Tienda de destino inexistente"
            }, status: :not_found
          elsif payload[:order_id].blank?
            render json: {
              status: "error",
              message: "Falta order_id"
            }, status: :unprocessable_entity
          elsif payload.dig(:restaurant, :id).to_s != restaurant.id.to_s ||
                payload.dig(:restaurant, :code) != restaurant.code
            render json: {
              status: "error",
              message: "La orden no corresponde a esta tienda."
            }, status: :unprocessable_entity
          else
            render json: {
              status: "received",
              order_id: payload[:order_id],
              restaurant_id: restaurant.id
            }, status: :created
          end
        end
      end
    end
  end
end
