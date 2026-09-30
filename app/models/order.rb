class Order < ApplicationRecord
  belongs_to :restaurant

  has_many :order_items

  enum :order_type, { pickup: 0, delivery: 1 }
  enum :dispatch_status, { pending: 0, sent: 1, error: 2 }

  validates :customer_name, :customer_phone, :order_type, presence: true
  validates :delivery_address, presence: true, if: :delivery?
  validates :total_clp, numericality: { only_integer: true, greater_than: 0 }
end
