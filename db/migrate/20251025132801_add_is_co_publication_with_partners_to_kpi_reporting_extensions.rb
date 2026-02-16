class AddIsCoPublicationWithPartnersToKpiReportingExtensions < ActiveRecord::Migration[8.0]
  def change
    add_column :kpi_reporting_extensions, :is_co_publication_with_partners, :boolean, null: true
  end
end
