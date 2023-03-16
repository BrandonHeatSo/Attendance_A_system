class Attendance < ApplicationRecord
  belongs_to :user

  validates :worked_on, presence: true
  validates :note, length: { maximum: 50 }

  # 出勤時間が存在しない場合、退勤時間は無効
  validate :finished_at_is_invalid_without_a_started_at
  # 退勤時間が存在しない場合、退勤時間は無効（勤怠編集画面での更新時のみ）
  validate :started_at_is_invalid_without_a_finished_at, on: :update_one_month_edit
  # 出勤・退勤時間どちらも存在する時、出勤時間より早い退勤時間は無効
  validate :started_at_than_finished_at_fast_if_invalid
  # 未来の出勤時間は無効
  validate :started_at_cannot_be_in_the_future, on: :update_one_month_edit
  # 未来の退勤時刻は無効
  validate :finished_at_cannot_be_in_the_future, on: :update_one_month_edit
  # 残業通知モーダルの「変更」ボックスにチェックが無い場合、残業承認結果の反映は無効。
  validate :update_overwork_result_is_invalid_without_check, on: :update_overwork_notice_check
  
  def finished_at_is_invalid_without_a_started_at
    errors.add(:started_at, "が必要です") if started_at.blank? && finished_at.present?
  end
  
  def started_at_is_invalid_without_a_finished_at
    errors.add(:finished_at, "が必要です") if finished_at.blank? && started_at.present?
  end

  def started_at_than_finished_at_fast_if_invalid
    if started_at.present? && finished_at.present?
      errors.add(:started_at, "より早い退勤時間は無効です") if started_at > finished_at
    end
  end
  
  def started_at_cannot_be_in_the_future
    errors.add(:started_at, "は未来の情報だと無効です") if started_at.present? && Date.current < worked_on
  end
  
  def finished_at_cannot_be_in_the_future
    errors.add(:finished_at, "は未来の情報だと無効です") if finished_at.present? && Date.current < worked_on
  end

  def update_overwork_result_is_invalid_without_check
    errors.add(:overwork_change_checkmark, "にチェックが必要です。") if overwork_change_checkmark == false
  end
end
