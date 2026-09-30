class Order < ApplicationRecord
  belongs_to :restaurant

  has_many :order_items
  accepts_nested_attributes_for :order_items

  enum :order_type, { pickup: 0, delivery: 1 }
  enum :dispatch_status, { pending: 0, sent: 1, error: 2 }

  validates :customer_name, :customer_phone, :order_type, presence: true
  validates :delivery_address, presence: true, if: :delivery?
  validates :order_items, presence: true
  validates :total_clp,
            numericality: { only_integer: true, greater_than: 0 },
            if: -> { order_items.present? }

  scope :dashboard_listing, -> {
    includes(:restaurant).order(created_at: :desc, id: :desc)
  }

  def assign_customer_data(customer)
    return if customer.blank?

    self.customer_name = customer[:name]
    self.customer_phone = customer[:phone]
  end

  def calculate_order_total
    self.total_clp = order_items.to_a.sum(&:calculate_item_total)
  end

  def dispatch_payload
    {
      order_id: id,
      restaurant: restaurant.as_json(only: %i[id code name]),
      customer: {
        name: customer_name,
        phone: customer_phone
      },
      order_type: order_type,
      delivery_address: delivery_address,
      items: order_items.map do |item|
        item.as_json(only: %i[quantity unit_price_clp]).merge(
          product: item.product.as_json(only: %i[sku name])
        )
      end,
      total_clp: total_clp
    }
  end
end