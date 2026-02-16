class ReplaceStringWithResearchGroupReference < ActiveRecord::Migration[8.0]
  def up
    remove_column :research_group_publications, :research_group, :string
    add_reference :research_group_publications, :research_group, foreign_key: true
  end

  def down
    remove_reference :research_group_publications, :research_group
    add_column :research_group_publications, :research_group, :string
  end
end
