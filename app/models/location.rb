class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :items, through: :inventory_items

  validates :name, presence: true
  validates :barcode, presence: true, uniqueness: true

  def total_items
    inventory_items.sum(:quantity)
  end
end
