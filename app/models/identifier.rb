class Identifier < ApplicationRecord
    belongs_to :publication

    enum :type, { 
        doi: "DOI",
        issn: "ISSN",
        essn: "eSSN",
        isbn: "ISBN",
        other: "other"
    }

    validates :type, presence: true
    validates :value, presence: true
end
