class AddOverworkColumnsToAttendances < ActiveRecord::Migration[5.1]
  def change
    add_column :attendances, :overwork_finish_time, :datetime
    add_column :attendances, :overwork_business_process_content, :string
    add_column :attendances, :overwork_next_day_checkmark, :boolean, default: false
    add_column :attendances, :overwork_change_checkmark, :boolean, default: false
    add_column :attendances, :overwork_stamp_select_superior, :string
    add_column :attendances, :overwork_stamp_confirm_step, :string
  end
end
