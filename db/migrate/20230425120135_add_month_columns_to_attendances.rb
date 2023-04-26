class AddMonthColumnsToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :month_change_checkmark, :boolean, default: false
    add_column :attendances, :month_stamp_select_superior, :string
    add_column :attendances, :month_stamp_confirm_step, :string
  end
end
