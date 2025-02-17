class CreatePublications < ActiveRecord::Migration[8.0]
  def change
    create_table :publications do |t|
      t.string :title, null: false
      t.integer :type, null: false
      t.integer :status, null: false
      t.string :author_list, null: false
      t.integer :journal_issue_id, null: true
      t.integer :conference_id, null: true
      t.date :publication_date, null: true
      t.string :link, null: false
      t.timestamps
    end
  end
end
