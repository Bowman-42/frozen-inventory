class IndividualInventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item
  belongs_to :reusable_barcode
  belongs_to :inventory_item

  validates :sequence_number, presence: true, uniqueness: { scope: :item_id }
  validates :added_at, presence: true

  before_validation :assign_barcode_and_sequence, on: :create
  after_create :update_item_total_quantity
  after_destroy :release_barcode
  after_destroy :update_item_total_quantity

  scope :oldest_first, -> { order(:added_at) }
  scope :newest_first, -> { order(added_at: :desc) }
  scope :by_location_and_item, ->(loc, itm) { where(location: loc, item: itm) }

  def storage_days
    (Time.current - added_at) / 1.day
  end

  def individual_barcode
    reusable_barcode.barcode
  end

  def self.sequence_for(barcode)
    # Legacy items get sequence 1, others take it from the barcode format "ITEM-00001"
    barcode.legacy_barcode? ? 1 : barcode.barcode.split('-').last.to_i
  end

  # Store this item under the barcode printed on its label, keeping location and added_at.
  # If another item currently holds that barcode, the two swap barcodes.
  def relabel!(label_barcode)
    return if reusable_barcode_id == label_barcode.id

    transaction do
      old_barcode = reusable_barcode
      other = label_barcode.individual_inventory_item

      # Park the other item's sequence number so the two can swap without hitting the unique index
      other&.update_columns(sequence_number: -other.sequence_number)

      update!(reusable_barcode: label_barcode, sequence_number: self.class.sequence_for(label_barcode))
      label_barcode.claim!

      if other
        other.update!(reusable_barcode: old_barcode, sequence_number: self.class.sequence_for(old_barcode))
      else
        old_barcode.release!
      end
    end
  end

private

  def assign_barcode_and_sequence
    # Keep the barcode printed on the label when one is given, otherwise take one from the pool
    if reusable_barcode
      reusable_barcode.claim!
    else
      self.reusable_barcode = ReusableBarcode.get_available_for_item(item)
    end
    self.sequence_number = self.class.sequence_for(reusable_barcode)
    self.added_at ||= Time.current
  end

  def release_barcode
    reusable_barcode&.release!
  end

  def update_item_total_quantity
    return unless item
    total = item.inventory_items.sum { |inv_item| inv_item.individual_inventory_items.count }
    item.update_column(:total_quantity, total)
  end
end