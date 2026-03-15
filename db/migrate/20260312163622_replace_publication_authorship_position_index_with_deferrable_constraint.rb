class ReplacePublicationAuthorshipPositionIndexWithDeferrableConstraint < ActiveRecord::Migration[8.0]
  def up
    remove_index :publication_authorships, column: [:publication_id, :position]

    execute <<~SQL
      ALTER TABLE publication_authorships
      ADD CONSTRAINT publication_authorships_publication_id_position_key
      UNIQUE (publication_id, position)
      DEFERRABLE INITIALLY DEFERRED
    SQL
  end

  def down
    execute <<~SQL
      ALTER TABLE publication_authorships
      DROP CONSTRAINT publication_authorships_publication_id_position_key
    SQL

    add_index :publication_authorships, [:publication_id, :position], unique: true
  end
end
