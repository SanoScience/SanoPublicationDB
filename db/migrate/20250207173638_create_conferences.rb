class CreateConferences < ActiveRecord::Migration[8.0]
  def change
    create_table :conferences do |t|
      t.string :name, null: false
      t.string :core, null: true
      t.date :start_date, null: false
      t.date :end_date, null: false
    end
  end
end
