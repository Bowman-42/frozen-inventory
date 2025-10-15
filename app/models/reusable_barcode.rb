class ReusableBarcode < ApplicationRecord
  belongs_to :item
  has_one :individual_inventory_item, dependent: :nullify

  validates :barcode, presence: true, uniqueness: true

  scope :available, -> { where(in_use: false) }
  scope :in_use, -> { where(in_use: true) }
  scope :legacy, -> { joins(:item).where('reusable_barcodes.barcode = items.barcode') }
  scope :generated, -> { joins(:item).where('reusable_barcodes.barcode != items.barcode') }

  def self.get_available_for_item(item)
    transaction do
      # Try to reuse an available barcode
      barcode = available.where(item: item).first

      if barcode
        barcode.update!(in_use: true, last_used_at: Time.current)
        return barcode
      end

      # Create new barcode with next sequence
      sequence = ItemIdCounter.next_for_item(item)
      create!(
        item: item,
        barcode: generate_barcode_for_item(item, sequence),
        in_use: true,
        last_used_at: Time.current
      )
    end
  end

  def release!
    update!(in_use: false, last_used_at: Time.current)
  end

  def legacy_barcode?
    barcode == item.barcode
  end

  # Pool management methods
  def self.pool_stats_for_item(item)
    {
      total_barcodes: where(item: item).count,
      in_use: in_use.where(item: item).count,
      available: available.where(item: item).count,
      utilization_rate: (in_use.where(item: item).count.to_f / where(item: item).count * 100).round(1)
    }
  end

  def self.ensure_pool_size(item, target_size = 50)
    current_count = where(item: item).count
    return if current_count >= target_size

    needed = target_size - current_count
    barcodes_to_create = []

    needed.times do
      sequence = ItemIdCounter.next_for_item(item)
      barcodes_to_create << {
        item: item,
        barcode: generate_barcode_for_item(item, sequence),
        in_use: false,
        created_at: Time.current
      }
    end

    insert_all(barcodes_to_create)
  end

private

  def self.generate_barcode_for_item(item, sequence)
    "#{item.barcode}-#{sequence.to_s.rjust(5, '0')}"
  end
end