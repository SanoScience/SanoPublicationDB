class OpenAccessExtension < ApplicationRecord
    include NotifiesPublicationOnChange

    belongs_to :publication

    enum :category, {
        green: 0,
        gold: 1
    }

    validates :publication, presence: true
    validate :validate_gold_fields

    def self.ransackable_attributes(auth_object = nil)
        [ "category", "gold_oa_funding_source" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "publication" ]
    end

    private

    def validate_gold_fields
        if green?
            errors.add(:gold_oa_charges, "should be empty for green OA") if gold_oa_charges.present?
            errors.add(:gold_oa_funding_source, "should be empty for green OA") if gold_oa_funding_source.present?
        end
    end
end
