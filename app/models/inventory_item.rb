class InventoryItem < ApplicationRecord
  belongs_to :location
  belongs_to :item

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :added_at, presence: true

  before_validation :set_added_at, on: :create

  scope :by_location, ->(location) { where(location: location) }
  scope :by_item, ->(item) { where(item: item) }

  private

  def set_added_at
    self.added_at ||= Time.current
  end
end
