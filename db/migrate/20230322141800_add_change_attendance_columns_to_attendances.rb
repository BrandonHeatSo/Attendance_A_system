class AddChangeAttendanceColumnsToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :before_change_started_at, :datetime
    add_column :attendances, :before_change_finished_at, :datetime
    add_column :attendances, :after_change_started_at, :datetime
    add_column :attendances, :after_change_finished_at, :datetime
    add_column :attendances, :change_attendance_next_day_checkmark, :boolean, default: false
    add_column :attendances, :change_attendance_change_checkmark, :boolean, default: false
    add_column :attendances, :change_attendance_stamp_select_superior, :string
    add_column :attendances, :change_attendance_stamp_confirm_step, :string
  end
end
