class JournalIssue < ApplicationRecord
    has_many :publications, foreign_key: :journal_issue_id

    validates :title, presence: true
end
