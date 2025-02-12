class AddJournalIssueReferenceToPublications < ActiveRecord::Migration[8.0]
  def change
    remove_column :publications, :journal_issue_id, :integer
    add_reference :publications, :journal_issues, foreign_key: { to_table: :journal_issues }, null: true
  end
end
