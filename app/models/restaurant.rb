class Restaurant < ApplicationRecord
  has_many :orders

  validates :name, :code, presence: true
  validates :code, uniqueness: true
end
