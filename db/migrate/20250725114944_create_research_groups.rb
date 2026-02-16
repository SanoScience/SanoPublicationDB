class CreateResearchGroups < ActiveRecord::Migration[8.0]
  def change
    create_table :research_groups do |t|
      t.string :name, null: false

      t.timestamps
    end
    add_index :research_groups, :name, unique: true
  end
end
