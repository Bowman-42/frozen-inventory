class Location < ApplicationRecord
  has_many :inventory_items, dependent: :destroy
  has_many :items, through: :inventory_items

  validates :name, presence: true
  validates :barcode, presence: true, uniqueness: true

  before_validation :generate_barcode, on: :create

  def total_items
    inventory_items.sum { |ii| ii.individual_inventory_items.count }
  end

  private

  def generate_barcode
    return if barcode.present?

    loop do
      self.barcode = "LOC#{SecureRandom.alphanumeric(8).upcase}"
      break unless Location.exists?(barcode: barcode)
    end
  end
end
