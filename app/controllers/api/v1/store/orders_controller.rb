module Api
  module V1
    module Store
      class OrdersController < ApplicationController
        def create
          if params[:order_id].present?
            render json: {
              status: "received",
              order_id: params[:order_id]
            }, status: :created
          else
            render json: {
              status: "error",
              message: "Falta order_id"
            }, status: :unprocessable_entity
          end
        end
      end
    end
  end
end