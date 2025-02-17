class Conference < ApplicationRecord
    has_many :publications, foreign_key: :conference_id

    validates :name, presence: true
    validates :start_date, presence: true
    validates :end_date, presence: true
    validate :valid_date_range

    private

    def valid_date_range
        if start_date && end_date && start_date > end_date
            errors.add(:end_date, "must be after start_date")
        end
    end
end
