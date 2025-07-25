class KpiReportingExtension < ApplicationRecord
    belongs_to :publication

    validates :publication, presence: true

    def self.ransackable_attributes(auth_object = nil)
        ["teaming_reporting_period", "pbn", "jcr"]
    end

    def self.ransackable_associations(auth_object = nil)
        ["publication"]
    end
end
