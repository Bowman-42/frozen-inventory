class IndividualInventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item
  belongs_to :reusable_barcode
  belongs_to :inventory_item

  validates :sequence_number, presence: true, uniqueness: { scope: :item_id }
  validates :added_at, presence: true

  before_validation :assign_barcode_and_sequence, on: :create
  after_destroy :release_barcode

  scope :oldest_first, -> { order(:added_at) }
  scope :newest_first, -> { order(added_at: :desc) }
  scope :by_location_and_item, ->(loc, itm) { where(location: loc, item: itm) }

  def storage_days
    (Time.current - added_at) / 1.day
  end

  def individual_barcode
    reusable_barcode.barcode
  end

private

  def assign_barcode_and_sequence
    self.reusable_barcode = ReusableBarcode.get_available_for_item(item)
    # Extract sequence number from the barcode or use counter
    if reusable_barcode.legacy_barcode?
      self.sequence_number = 1  # Legacy items get sequence 1
    else
      # Extract sequence from barcode format "ITEM-00001"
      self.sequence_number = reusable_barcode.barcode.split('-').last.to_i
    end
    self.added_at ||= Time.current
  end

  def release_barcode
    reusable_barcode&.release!
  end
end