class Order < ApplicationRecord
  belongs_to :restaurant

  has_many :order_items
  accepts_nested_attributes_for :order_items

  enum :order_type, { pickup: 0, delivery: 1 }, validate: true
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
end
