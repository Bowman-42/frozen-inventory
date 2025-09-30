class Item < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :locations, through: :inventory_items

  validates :name, presence: true
  validates :barcode, presence: true, uniqueness: true

  def total_quantity
    inventory_items.sum(:quantity)
  end

  def locations_with_quantity
    inventory_items.includes(:location).map do |inv_item|
      {
        location: inv_item.location,
        quantity: inv_item.quantity,
        added_at: inv_item.added_at
      }
    end
  end
end
