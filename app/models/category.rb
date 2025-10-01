class Category < ApplicationRecord
  has_many :items, dependent: :nullify

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 }

  scope :ordered, -> { order(:name) }

  def to_s
    name
  end
end
