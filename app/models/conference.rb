class Conference < ApplicationRecord
    has_many :publications, foreign_key: :conference_id

    validates :name, presence: true
    validate :valid_date_range

    def self.ransackable_attributes(auth_object = nil)
        [ "name" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "publications" ]
    end

    private

    def valid_date_range
        if start_date && end_date && start_date > end_date
            errors.add(:end_date, "must be after start_date")
        end
    end
end
