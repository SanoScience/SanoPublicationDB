class RenamePublicationForeignKeys < ActiveRecord::Migration[8.0]
  def change
    rename_column :publications, :conferences_id, :conference_id
    rename_column :publications, :journal_issues_id, :journal_issue_id

    if index_exists?(:publications, :conferences_id)
      rename_index :publications, :index_publications_on_conferences_id, :index_publications_on_conference_id
    end

    if index_exists?(:publications, :journal_issues_id)
      rename_index :publications, :index_publications_on_journal_issues_id, :index_publications_on_journal_issue_id
    end
  end
end
