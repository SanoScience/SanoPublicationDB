class Identifier < ApplicationRecord
    belongs_to :publication

    enum :category, { 
        doi: "DOI",
        issn: "ISSN",
        essn: "eSSN",
        isbn: "ISBN",
        other: "other"
    }

    validates :category, presence: true
    validates :value, presence: true
end
