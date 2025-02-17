class AddConferenceReferenceToPublications < ActiveRecord::Migration[8.0]
  def change
    remove_column :publications, :conference_id, :integer
    add_reference :publications, :conferences, foreign_key: { to_table: :conferences }, null: true
  end
end
