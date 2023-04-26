class AttendancesController < ApplicationController
  before_action :set_user, only: [:show_overwork_notice, :edit_change_attendance_request, :send_change_attendance_request, :show_change_attendance_notice, :update_change_attendance_notice]
  before_action :set_attendance, only: [:update, :edit_overwork_request, :send_overwork_request, :show_overwork_notice, :edit_change_attendance_request, :send_change_attendance_request, :log_change_approval]
  before_action :logged_in_user, only: [:update, :edit_change_attendance_request, :send_change_attendance_request, :edit_overwork_request, :send_overwork_request, :log_change_approval]
  before_action :admin_or_correct_user, only: [:update, :edit_change_attendance_request, :send_change_attendance_request]
  before_action :set_one_month, only: [:edit_change_attendance_request]

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
      flash[:success] = "#{@attendance.worked_on}の残業を申請しました。"
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
    end
    redirect_to user_url(@user)
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐。
    flash[:danger] = "無効な入力データがあった為、残業更新をキャンセルしました。"
    redirect_to user_url(@user)
  end

  def edit_change_attendance_request
    @superior = User.where(superior:true).where.not(id:current_user.id)
  end

  def send_change_attendance_request
    @superior = User.where(superior:true).where.not(id:current_user.id)
    ActiveRecord::Base.transaction do # 勤怠変更の申請用トランザクションを開始。
      change_attendance_request_params.each do |id, item|
        if item[:change_attendance_stamp_select_superior].present?
          if item[:started_at].blank? || item[:finished_at].blank?
            flash[:danger] = "出勤時間と退勤時間は両方とも申請に必要です。"
            redirect_to attendances_edit_change_attendance_request_user_url(date: params[:date]) and return
          end
          
          attendance = Attendance.find(id)
          before_start_time_store = attendance.started_at.to_time if attendance.started_at.present? # 変更前の出社時間、ＤＢ格納のみ。
          before_finish_time_store = attendance.finished_at.to_time if attendance.finished_at.present? # 変更前の退社時間、ＤＢ格納のみ。
          change_attendance_next_day_checkmark = item[:change_attendance_next_day_checkmark] # 変更後の翌日チェックの値を一時的に保存.

          if ( before_start_time_store != item[:started_at].to_time ) || ( before_finish_time_store != item[:finished_at].to_time )
            attendance.after_change_started_at = item[:started_at]
            attendance.after_change_finished_at = item[:finished_at]
            attendance.note = item[:note]
            attendance.change_attendance_stamp_select_superior = item[:change_attendance_stamp_select_superior]
            attendance.change_attendance_next_day_checkmark = change_attendance_next_day_checkmark # 一時保存した翌日チェック値を使ってカラムに代入.
            attendance.change_attendance_stamp_confirm_step = "申請中"
            attendance.save!(context: :send_change_attendance_edit) # オブジェクトを変更せずにバリデーション付ＤＢ保存。
            flash[:success] = "勤怠変更を申請しました。"
          end
        else
          next # 条件が合わなかったら次のループに進む.
        end
      end
    end
    redirect_to user_url(date: params[:date])
  rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐です。
    flash[:danger] = "無効な入力データがあった為、勤怠変更の申請をキャンセルしました。<br>
                     （翌日チェック無しに、出勤時間より退勤時間が早い日がある・・・などの原因が考えられます。）"
    redirect_to attendances_edit_change_attendance_request_user_url(date: params[:date])
  end

  def show_change_attendance_notice
    @change_attendances = Attendance.where(change_attendance_stamp_select_superior: @user.id, change_attendance_stamp_confirm_step: "申請中")
                                    .order(:user_id,:worked_on)
                                    .group_by(&:user_id)
  end

  def update_change_attendance_notice
    ActiveRecord::Base.transaction do # 勤怠変更通知の更新用トランザクションを開始。
      change_attendance_notice_params.each do |id, item|
        attendance = Attendance.find(id)
        unless item[:change_attendance_change_checkmark].blank?
          if item[:change_attendance_stamp_confirm_step] == "承認"
            if attendance.before_change_started_at.blank? && attendance.before_change_finished_at.blank?
              attendance.before_change_started_at = attendance.started_at
              attendance.before_change_finished_at = attendance.finished_at
            end
            attendance.started_at = attendance.after_change_started_at
            attendance.finished_at = attendance.after_change_finished_at
            attendance.after_change_started_at = nil
            attendance.after_change_finished_at = nil
          elsif item[:change_attendance_stamp_confirm_step] == "否認"
            attendance.after_change_started_at = nil
            attendance.after_change_finished_at = nil
          elsif item[:change_attendance_stamp_confirm_step] == "なし"
            attendance.started_at = nil
            attendance.finished_at = nil
            attendance.after_change_started_at = nil
            attendance.after_change_finished_at = nil
            attendance.note = nil
            item[:change_attendance_stamp_confirm_step] = nil
            item[:change_attendance_next_day_checkmark] = nil
            item[:change_attendance_stamp_select_superior] = nil
            attendance.update_attributes!(item) # オブジェクト変更＆ＤＢに保存。
            flash[:success] = "勤怠変更申請を取り消し、該当日の勤怠内容を削除しました。"
          end
          item[:change_attendance_change_checkmark] = nil
          attendance.update_attributes!(item) # オブジェクト変更＆ＤＢに保存。
          flash[:success] = "勤怠変更申請に対し、結果を送信しました。"
        else
          flash[:danger] = "変更チェックボックスにチェックが無い申請に対しては、結果を送信しませんでした。"
        end
      end
    end
    redirect_to user_url(@user)
  # rescue ActiveRecord::RecordInvalid # トランザクションによるエラーの分岐。
  rescue ActiveRecord::RecordInvalid => e
    logger.error("Transaction failed: #{e.message}")
    flash[:danger] = "無効な入力データがあった為、勤怠変更の更新をキャンセルしました。"
    redirect_to user_url(@user)
  end

  def edit_month_request
  end

  def send_month_request
  end

  def show_month_notice
  end

  def update_month_notice
  end

  def log_change_approval
    @user = User.find(params[:user_id])
    if params["select_year(1i)"].present? && params["select_month(2i)"].present?
      @first_day = (params["select_year(1i)"] + "-" + params["select_month(2i)"] + "-01").to_date
      @attendances = @user.attendances.where(worked_on: @first_day..@first_day.end_of_month, change_attendance_stamp_confirm_step: "承認").order(:worked_on)
    end
  end

  private

    # 1ヶ月分の勤怠情報を扱います。
    def change_attendance_request_params
      params.require(:user).permit(attendances: [:started_at,
                                                 :finished_at,
                                                 :after_change_started_at,
                                                 :after_change_finished_at,
                                                 :change_attendance_next_day_checkmark,
                                                 :change_attendance_stamp_select_superior,
                                                 :change_attendance_stamp_confirm_step,
                                                 :note])[:attendances]
    end

    def change_attendance_notice_params
      params.require(:user).permit(attendances: [:change_attendance_change_checkmark,
                                                 :change_attendance_next_day_checkmark,
                                                 :change_attendance_stamp_confirm_step])[:attendances]
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
