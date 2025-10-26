class KpiReportingExtension < ApplicationRecord
    belongs_to :publication

    before_validation :nilify_blanks

    with_options on: :ui do
        validates :is_new_method_technique,
                :is_methodology_application,
                :is_polish_med_researcher_involved,
                :is_co_publication_with_partners,
                :is_peer_reviewed,
                inclusion: { in: [true, false], message: "should be selected" }
    end

    def self.ransackable_attributes(auth_object = nil)
        [ "teaming_reporting_period", "pbn", "jcr" ]
    end

    def self.ransackable_associations(auth_object = nil)
        [ "publication" ]
    end

    private

    def nilify_blanks
        self.teaming_reporting_period = teaming_reporting_period.presence
        self.subsidy_points           = subsidy_points.presence
    end
end
