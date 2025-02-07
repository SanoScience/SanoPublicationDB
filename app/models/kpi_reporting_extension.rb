class KpiReportingExtension < ApplicationRecord
    belongs_to :publication, optional: false
end
