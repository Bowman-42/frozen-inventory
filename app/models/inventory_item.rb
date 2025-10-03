class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :added_at, presence: true

  before_validation :set_added_at, on: :create
  after_create :update_item_total_quantity
  after_update :update_item_total_quantity, if: :saved_change_to_quantity?
  after_destroy :update_item_total_quantity

  scope :by_location, ->(location) { where(location: location) }
  scope :by_item, ->(item) { where(item: item) }
  scope :oldest_per_item, -> {
    joins("INNER JOIN (
      SELECT item_id, MIN(added_at) as oldest_added_at
      FROM inventory_items
      GROUP BY item_id
    ) oldest ON inventory_items.item_id = oldest.item_id
              AND inventory_items.added_at = oldest.oldest_added_at")
    .includes(:location)
  }

  private

  def set_added_at
    self.added_at ||= Time.current
  end

  def update_item_total_quantity
    return unless item

    # Calculate the sum of all quantities for this item across all locations
    total = item.inventory_items.sum(:quantity)

    # Update the cached total_quantity
    item.update_column(:total_quantity, total)
  end
end
