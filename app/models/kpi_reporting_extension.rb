class KpiReportingExtension < ApplicationRecord
    belongs_to :publication, dependent: :destroy

    validates :publication, presence: true
end
