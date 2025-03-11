class KpiReportingExtension < ApplicationRecord
    belongs_to :publication

    validates :publication, presence: true
end
