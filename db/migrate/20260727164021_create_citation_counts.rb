class CreateCitationCounts < ActiveRecord::Migration[8.0]
  def change
    create_table :citation_counts do |t|
      t.references :publication, null: false, foreign_key: true
      t.string :source, null: false
      t.integer :count, null: false, default: 0
      t.datetime :recorded_at, null: false

      t.timestamps
    end

    add_index :citation_counts, [ :publication_id, :source, :recorded_at ]
  end
end
