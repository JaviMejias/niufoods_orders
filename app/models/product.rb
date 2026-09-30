class Product < ApplicationRecord
  has_many :order_items

  validates :name, :sku, presence: true
  validates :sku, uniqueness: true
  validates :price_clp, numericality: { only_integer: true, greater_than: 0 }
end
