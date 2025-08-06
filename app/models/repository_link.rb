class RepositoryLink < ApplicationRecord
    include UrlValidatable
    validates_url_of :value

    belongs_to :publication

    enum :repository, {
        dataverse: "Dataverse",
        zenodo: "Zenodo",
        osf: "OSF",
        other: "other"
    }

    validates :publication, presence: true
    validates :repository, presence: true
    validates :value, presence: true
end
