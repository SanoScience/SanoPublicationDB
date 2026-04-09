class RemoveAuthorListFromPublications < ActiveRecord::Migration[8.0]
  def change
    remove_column :publications, :author_list, :string
  end

  def down
    add_column :publications, :author_list, :string
  end
end
