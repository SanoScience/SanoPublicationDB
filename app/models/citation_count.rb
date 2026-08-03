class CitationCount < ApplicationRecord
  belongs_to :publication

  validates :source, presence: true
  validates :count, presence: true, numericality: { only_integer: true, greater_than_or_equal_to: 0 }
  validates :recorded_at, presence: true
end
