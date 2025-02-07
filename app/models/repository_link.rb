class RepositoryLink < ApplicationRecord
    belongs_to :publication

    enum :repository, { 
        dataverse: "Dataverse",
        zenodo: "Zenodo",
        osf: "OSF",
        other: "other"
    }

    validates :value, presence: true
end
