class JournalIssue < ApplicationRecord
    has_many :publications, foreign_key: :journal_issue_id

    before_save :nilify_blanks

    validates :title, presence: true

    def self.ransackable_attributes(auth_object = nil)
        [ "title" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "publications" ]
    end

    private

    def nilify_blanks
        self.journal_num = journal_num.presence
        self.publisher = publisher.presence
        self.volume = volume.presence
        self.impact_factor = impact_factor.presence
    end
end
