class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :product

  validates :quantity,
            numericality: { only_integer: true, greater_than: 0 }
  validates :unit_price_clp,
            numericality: { only_integer: true, greater_than: 0 },
            if: -> { product.present? }

  def calculate_item_total
    return 0 unless product && quantity.present?

    self.unit_price_clp = product.price_clp
    item_total
  end

  def item_total
    return 0 unless unit_price_clp && quantity

    unit_price_clp * quantity
  end
end