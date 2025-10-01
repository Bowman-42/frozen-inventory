class Item < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :locations, through: :inventory_items

  validates :name, presence: true
  validates :barcode, presence: true, uniqueness: true

  before_validation :generate_barcode, on: :create

  # total_quantity is now cached in the database column
  # Rails will automatically read from the total_quantity attribute

  def locations_with_quantity
    inventory_items.includes(:location).map do |inv_item|
      {
        location: inv_item.location,
        quantity: inv_item.quantity,
        added_at: inv_item.added_at
      }
    end
  end

  private

  def generate_barcode
    return if barcode.present?

    loop do
      self.barcode = "ITM#{SecureRandom.alphanumeric(8).upcase}"
      break unless Item.exists?(barcode: barcode)
    end
  end
end
