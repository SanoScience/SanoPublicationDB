class PublicationAuthorship < ApplicationRecord
  belongs_to :publication
  belongs_to :author, optional: true

  accepts_nested_attributes_for :author

  validates :position, presence: true,
                       numericality: { only_integer: true, greater_than: 0 }

  validates :publication, presence: true
  validates :author, presence: true

  validate :author_or_nested_author_present

  private

  def author_or_nested_author_present
    return if marked_for_destruction?
    return if author_id.present?
    return if author.present?

    errors.add(:author, "must be selected or created")
  end
end
