class ItemIdCounter < ApplicationRecord
  belongs_to :item

  validates :last_counter, presence: true, numericality: { greater_than_or_equal_to: 0 }

  def self.next_for_item(item)
    counter_record = find_or_create_by(item: item)
    counter_record.with_lock do
      counter_record.increment!(:last_counter)
      counter_record.last_counter
    end
  end
end