class AddPeerReviewToKpiReportingExtensions < ActiveRecord::Migration[8.0]
  def change
    add_column :kpi_reporting_extensions, :is_peer_reviewed, :boolean
  end
end
