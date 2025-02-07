class CreateIdentifiers < ActiveRecord::Migration[8.0]
  def change
    create_table :identifiers do |t|
      t.belongs_to :publication
      t.string :type
      t.string :value
    end
  end
end
