class Identifier < ApplicationRecord
    belongs_to :publication, dependent: :destroy

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
end
