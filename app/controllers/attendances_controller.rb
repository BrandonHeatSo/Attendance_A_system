class AttendancesController < ApplicationController
  before_action :set_user, only: [:edit_change_attendance_request, :send_change_attendance_request, :show_overwork_notice]
  before_action :set_attendance, only: [:update, :edit_overwork_request, :send_overwork_request, :show_overwork_notice]
  before_action :logged_in_user, only: [:update, :edit_change_attendance_request, :edit_overwork_request, :send_overwork_request]
  before_action :admin_or_correct_user, only: [:update, :edit_change_attendance_request, :send_change_attendance_request]
  before_action :set_one_month, only: :edit_change_attendance_request

  UPDATE_ERROR_MSG = "勤怠登録に失敗しました。やり直してください。"

  def update
    @user = User.find(params[:user_id])
    # 出勤時間が未登録であることを判定します。
    if @attendance.started_at.nil?
      if @attendance.update_attributes(started_at: Time.current.floor_to(15.minutes).change(sec: 0))
        flash[:info] = "おはようございます！"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    elsif @attendance.finished_at.nil?
      if @attendance.update_attributes(finished_at: Time.current.floor_to(15.minutes).change(sec: 0))
        flash[:info] = "お疲れ様でした。"
      else
        flash[:danger] = UPDATE_ERROR_MSG
      end
    end
    redirect_to @user
  end

  def edit_overwork_request
    @user = User.find(params[:user_id])
    @superior = User.where(superior:true).where.not(id:current_user.id)
  end

  def send_overwork_request
    @user = User.find(params[:user_id])
    @superior = User.where(superior:true).where.not(id:current_user.id)
    if overwork_request_params[:overwork_stamp_select_superior].present? && overwork_request_params[:overwork_finish_time].present? 
      @attendance.update(overwork_request_params)
      flash[:success] = "#{@user.name}の残業を申請しました。"
    else
      flash[:danger] = "終了予定時間入力と上長選択の両方が無いと、残業は申請できません。"
    end
    redirect_to user_url(@user)
  end

  def show_overwork_notice
    @overwork_attendances = Attendance.where(overwork_stamp_select_superior: @user.id, overwork_stamp_confirm_step: "申請中")
                                      .order(:user_id, :worked_on)
                                      .group_by(&:user_id)
  end

  def update_overwork_notice
    @user = User.find(params[:user_id])
    ActiveRecord::Base.transaction do # 残業通知の更新用トランザクションを開始。
      overwork_notice_params.each do |id, item|
        attendance = Attendance.find(id)
        unless item[:overwork_change_checkmark].blank? # 変更チェック有無用の分岐。
          if item[:overwork_stamp_confirm_step] == "なし" # 申請結果「なし」用の分岐。
            attendance.overwork_finish_time = nil
            attendance.overwork_stamp_select_superior = nil
            attendance.overwork_business_process_content = nil
            item[:overwork_stamp_confirm_step] = nil
            item[:overwork_change_checkmark] = nil
            item[:overwork_next_day_checkmark] = nil
            attendance.update_attributes!(item) # オブジェクト変更＆ＤＢに保存。
            flash[:success] = "残業申請を取り消し、残業申請内容を削除しました。"
          else
          attendance.update_attributes!(item) # オブジェクト変更＆ＤＢに保存。
          flash[:success] = "残業申請に対し、結果を送信しました。"
          end
        else
          flash[:danger] = "変更チェックボックスにチェックを入れてください。"
        end
      end
      redirect_to user_url(@user)
    end
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐。
    flash[:danger] = "無効な入力データがあった為、残業更新をキャンセルしました。"
    redirect_to user_url(@user)
  end

  def edit_change_attendance_request
    @superior = User.where(superior:true).where.not(id:current_user.id)
  end

  def send_change_attendance_request
    ActiveRecord::Base.transaction do # トランザクションを開始します。
      attendances_params.each do |id, item|
        attendance = Attendance.find(id)
        attendance.assign_attributes(item) # オブジェクト変更のみ。ＤＢには未保存。
        attendance.save!(context: :update_one_month_edit) # オブジェクトのバリデーション付ＤＢ保存。
      end
    end
    flash[:success] = "1ヶ月分の勤怠情報を更新しました。"
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、更新をキャンセルしました。"
    redirect_to attendances_edit_change_attendace_request_user_url(date: params[:date])
  end

  def show_change_attendance_notice
  end

  def update_change_attendance_notice
  end

  private

    # 1ヶ月分の勤怠情報を扱います。
    def attendances_params
      params.require(:user).permit(attendances: [:started_at,
                                                 :finished_at,
                                                 :after_change_started_at,
                                                 :after_change_finished_at,
                                                 :change_attendance_next_day_checkmark,
                                                 :change_attendance_stamp_select_superior,
                                                 :change_attendance_stamp_confirm_step,
                                                 :note])[:attendances]
    end
    
    def overwork_request_params
      params.require(:attendance).permit(:overwork_finish_time,
                                         :overwork_next_day_checkmark,
                                         :overwork_business_process_content,
                                         :overwork_stamp_select_superior,
                                         :overwork_stamp_confirm_step)
    end
    
    def overwork_notice_params
      params.require(:user).permit(attendances: [:overwork_change_checkmark,
                                                 :overwork_stamp_confirm_step])[:attendances]
    end

    # beforeフィルター

    def set_attendance
      @attendance = Attendance.find(params[:id])
    end

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:user_id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "編集権限がありません。"
        redirect_to(root_url)
      end  
    end
end
