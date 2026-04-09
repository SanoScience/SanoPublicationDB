class CreateAuthorsAndPublicationAuthorships < ActiveRecord::Migration[8.0]
  def change
    create_table :authors do |t|
      t.string :first_name
      t.string :last_name
      t.string :collective_name
      t.string :title
    end

    create_table :publication_authorships do |t|
      t.references :publication, null: false, foreign_key: { on_delete: :cascade }
      t.references :author, null: false, foreign_key: { on_delete: :cascade }
      t.integer :position, null: false
    end

    add_index :publication_authorships, [ :publication_id, :position ], unique: true
    add_index :publication_authorships, [ :publication_id, :author_id ], unique: true
  end
end
