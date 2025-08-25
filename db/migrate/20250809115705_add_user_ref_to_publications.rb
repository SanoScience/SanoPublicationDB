class AddUserRefToPublications < ActiveRecord::Migration[8.0]
  def change
    add_reference :publications, :owner, foreign_key: { to_table: :users, on_delete: :nullify }
  end
end
