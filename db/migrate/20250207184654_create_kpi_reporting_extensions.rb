class CreateKpiReportingExtensions < ActiveRecord::Migration[8.0]
  def change
    create_table :kpi_reporting_extensions do |t|
      t.belongs_to :publication, null: false, foreign_key: true
      t.integer :teaming_reporting_period, null: true
      t.string :invoice_number, null: true
      t.boolean :pbn, null: true
      t.boolean :jcr, null: true
      t.boolean :is_added_ft_portal, null: true
      t.boolean :is_checked, null: true
      t.boolean :is_new_method_technique, null: true
      t.boolean :is_methodology_application, null: true
      t.boolean :is_polish_med_researcher_involved, null: true
      t.integer :subsidy_points, null: true

      t.timestamps
    end
  end
end
