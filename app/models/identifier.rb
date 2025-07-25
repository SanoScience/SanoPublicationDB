class Identifier < ApplicationRecord
    belongs_to :publication

    enum :category, {
        doi: "DOI",
        issn: "ISSN",
        essn: "eSSN",
        isbn: "ISBN",
        other: "other"
    }

    validates :publication, presence: true
    validates :category, presence: true
    validates :value, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["category", "value"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["publication"]
    end
end
