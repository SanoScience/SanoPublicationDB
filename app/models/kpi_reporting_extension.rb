class KpiReportingExtension < ApplicationRecord
    belongs_to :publication

    validates :publication, presence: true
    validates :is_new_method_technique,
              :is_methodology_application,
              :is_polish_med_researcher_involved,
              :is_co_publication_with_partners,
              :is_peer_reviewed,
              inclusion: { in: [true, false], message: "should be selected" }

    def self.ransackable_attributes(auth_object = nil)
        [ "teaming_reporting_period", "pbn", "jcr" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "publication" ]
    end
end
