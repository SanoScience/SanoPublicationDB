class AddNotNullConstraints < ActiveRecord::Migration[8.0]
  def change
    change_column_null :identifiers, :publication_id, false
    change_column_null :identifiers, :category, false
    change_column_null :identifiers, :value, false

    change_column_null :repository_links, :publication_id, false
    change_column_null :repository_links, :repository, false
    change_column_null :repository_links, :value, false

    change_column_null :research_group_publications, :publication_id, false
    change_column_null :research_group_publications, :research_group, false
    change_column_null :research_group_publications, :is_primary, false

    # Remove old foreign keys
    remove_foreign_key :publications, :conferences
    remove_foreign_key :publications, :journal_issues
    remove_foreign_key :kpi_reporting_extensions, :publications
    remove_foreign_key :open_access_extensions, :publications

    # Add new foreign keys
    add_foreign_key :identifiers, :publications, on_delete: :cascade
    add_foreign_key :repository_links, :publications, on_delete: :cascade
    add_foreign_key :research_group_publications, :publications, on_delete: :cascade
    add_foreign_key :kpi_reporting_extensions, :publications, on_delete: :cascade
    add_foreign_key :open_access_extensions, :publications, on_delete: :cascade
    add_foreign_key :publications, :conferences, on_delete: :nullify
    add_foreign_key :publications, :journal_issues, on_delete: :nullify
  end
end
