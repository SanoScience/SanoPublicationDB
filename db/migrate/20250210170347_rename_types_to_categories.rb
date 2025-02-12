class RenameTypesToCategories < ActiveRecord::Migration[8.0]
  def change
    rename_column :publications, :type, :category
    rename_column :identifiers, :type, :category
    rename_column :open_access_extensions, :type, :category
  end
end
