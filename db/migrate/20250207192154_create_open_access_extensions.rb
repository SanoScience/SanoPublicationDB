class CreateOpenAccessExtensions < ActiveRecord::Migration[8.0]
  def change
    create_table :open_access_extensions do |t|
      t.belongs_to :publication, null: false, foreign_key: true
      t.decimal :gold_oa_charges, null: true
      t.string :gold_oa_funding_source, null: true
      t.integer :type, null: false

      t.timestamps
    end
  end
end
