class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity, :unit_price_clp,
            numericality: { only_integer: true, greater_than: 0 }
end
