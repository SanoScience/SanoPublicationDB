class ResearchGroupPublication < ApplicationRecord
    belongs_to :publication
    belongs_to :research_group

    accepts_nested_attributes_for :research_group, allow_destroy: true, reject_if: :all_blank

    validates :publication, presence: true
    validates :research_group, presence: true
end
