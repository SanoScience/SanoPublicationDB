class AllowNullsInPublicationLink < ActiveRecord::Migration[8.0]
  def change
    change_column_null :publications, :link, true
  end
end
