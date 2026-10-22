class RemovalHistory < ApplicationRecord
  belongs_to :item, optional: true
  belongs_to :location, optional: true

  scope :recent_first, -> { order(removed_at: :desc) }
  scope :excluding_moves, -> { where.not(removal_method: "moved") }
end
