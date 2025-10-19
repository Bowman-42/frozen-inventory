class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item
  has_many :individual_inventory_items, dependent: :destroy

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

  # Individual item management methods
  def add_individual_item!(added_at: nil)
    individual_item = IndividualInventoryItem.create!(
      location: location,
      item: item,
      inventory_item: self,
      added_at: added_at
    )

    # Update aggregated quantity and added_at
    update_aggregate_fields

    individual_item
  end

  def remove_individual_item!(strategy: :fifo, target: nil)
    individual_item = if target
      target
    else
      case strategy
      when :fifo
        individual_inventory_items.oldest_first.first
      when :lifo
        individual_inventory_items.newest_first.first
      else
        raise ArgumentError, "Unknown strategy: #{strategy}"
      end
    end

    return nil unless individual_item

    removed_item_info = {
      individual_barcode: individual_item.individual_barcode,
      sequence_number: individual_item.sequence_number,
      added_at: individual_item.added_at,
      original_added_at: individual_item.added_at,
      storage_days: individual_item.storage_days
    }

    individual_item.destroy!

    # Update aggregated fields or destroy if empty
    if individual_inventory_items.count == 0
      destroy!
      removed_item_info.merge(completely_removed: true)
    else
      update_aggregate_fields
      removed_item_info.merge(completely_removed: false)
    end
  end

  # API compatibility methods
  def quantity
    individual_inventory_items.count
  end

  def added_at
    individual_inventory_items.minimum(:added_at) || super
  end

private

  def update_aggregate_fields
    oldest_item = individual_inventory_items.oldest_first.first
    update_columns(
      added_at: oldest_item&.added_at || Time.current
    )
  end

  def set_added_at
    self.added_at ||= Time.current
  end

  def update_item_total_quantity
    return unless item
    total = item.inventory_items.sum { |inv_item| inv_item.individual_inventory_items.count }
    item.update_column(:total_quantity, total)
  end
end
