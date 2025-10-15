class Item < ApplicationRecord
  belongs_to :category, optional: true
  has_many :inventory_items, dependent: :destroy
  has_many :locations, through: :inventory_items
  has_many :individual_inventory_items, dependent: :destroy
  has_many :item_id_counters, dependent: :destroy
  has_many :reusable_barcodes, dependent: :destroy

  validates :name, presence: true
  validates :barcode, presence: true, uniqueness: true

  before_validation :generate_barcode, on: :create

  scope :by_category, ->(category) { where(category: category) }
  scope :with_category, -> { joins(:category) }
  scope :without_category, -> { where(category: nil) }

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

  def oldest_inventory_item
    inventory_items.includes(:location).order(:added_at).first
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
