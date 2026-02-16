class ResearchGroup < ApplicationRecord
    has_many :research_group_publications, dependent: :restrict_with_error
    has_many :publications, through: :research_group_publications

    validates :name, presence: true, uniqueness: true
end
