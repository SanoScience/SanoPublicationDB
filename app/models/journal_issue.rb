class JournalIssue < ApplicationRecord
    has_many :publications, foreign_key: :journal_issue_id

    validates :title, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["title"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["publications"]
    end
end
