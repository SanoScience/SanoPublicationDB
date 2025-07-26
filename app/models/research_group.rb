class ResearchGroup < ApplicationRecord
    has_many :research_group_publications
    has_many :publications, through: :research_group_publications

    validates :name, presence: true, uniqueness: true
end
