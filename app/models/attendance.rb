class Attendance < ApplicationRecord
  belongs_to :user

  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }

  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at
  # 退勤時間が存在しない場合、出勤時間は無効（勤怠編集画面での更新時のみ）
  validate :started_at_is_invalid_without_a_finished_at, on: :update_one_month_edit
  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効（翌日チェックが無い場合のみ）
  validate :started_at_than_finished_at_fast_if_invalid
  # 未来の出勤時間は無効
  validate :started_at_cannot_be_in_the_future, on: :update_one_month_edit
  # 未来の退勤時刻は無効
  validate :finished_at_cannot_be_in_the_future, on: :update_one_month_edit
  
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def started_at_is_invalid_without_a_finished_at
    errors.add(:finished_at, "が必要です") if after_change_finished_at.blank? && after_change_started_at.present?
  end
  
  def started_at_than_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      # 「退勤時間が翌日の場合」かつ「出勤時間が退勤時間より遅い場合」はエラーを返さない
      if !change_attendance_next_day_checkmark && started_at > finished_at
        errors.add(:started_at, "より早い退勤時間は無効です")
      end
    end
  end
  
  def started_at_cannot_be_in_the_future
    errors.add(:started_at, "は未来の情報だと無効です") if started_at.present? && Date.current < worked_on
  end
  
  def finished_at_cannot_be_in_the_future
    errors.add(:finished_at, "は未来の情報だと無効です") if finished_at.present? && Date.current < worked_on
  end
end
