class CreateResearchGroupPublications < ActiveRecord::Migration[8.0]
  def change
    create_table :research_group_publications do |t|
      t.belongs_to :publication
      t.string :research_group
      t.boolean :is_primary
    end
  end
end
