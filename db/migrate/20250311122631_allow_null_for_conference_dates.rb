class AllowNullForConferenceDates < ActiveRecord::Migration[8.0]
  def change
    change_column_null :conferences, :start_date, true
    change_column_null :conferences, :end_date, true
  end
end
