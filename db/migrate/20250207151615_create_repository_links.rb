class CreateRepositoryLinks < ActiveRecord::Migration[8.0]
  def change
    create_table :repository_links do |t|
      t.belongs_to :publication
      t.string :repository
      t.string :value
    end
  end
end
