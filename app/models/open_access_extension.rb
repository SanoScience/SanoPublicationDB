class OpenAccessExtension < ApplicationRecord
    belongs_to :publication, dependent: :destroy

    enum :category, {
        green: 0,
        gold: 1
    }

    validates :publication, presence: true
    validates :category, presence: true, inclusion: { in: categories.keys }
    validate :validate_gold_fields

    private

    def validate_gold_fields
        if green?
            errors.add(:gold_oa_charges, "should be empty for green OA") if gold_oa_charges.present?
            errors.add(:gold_oa_funding_source, "should be empty for green OA") if gold_oa_funding_source.present?
        end
    end
end
