class CreateJournalIssues < ActiveRecord::Migration[8.0]
  def change
    create_table :journal_issues do |t|
      t.string :title, null: false
      t.string :journal_num, null: true
      t.string :publisher, null: true
      t.integer :volume, null: true
      t.float :impact_factor, null: true
    end
  end
end
