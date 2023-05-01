class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :search, :csv_import, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :attendance_at_work_employees]
  before_action :correct_user, only: :edit
  before_action :admin_or_correct_user, only: :update
  before_action :admin_user, only: [:index, :search, :csv_import, :destroy, :edit_basic_info, :update_basic_info, :attendance_at_work_employees]
  before_action :admin_not_allowed_to_show, only: :show
  before_action :set_one_month, only: :show
  before_action :set_q, only: [:index, :search]

  def index
    @users = User.paginate(page: params[:page], per_page: 5).where.not(admin: true)
  end

  def show
    @attendance = @user.attendances.find_by(worked_on: @first_day)
    @worked_sum = @attendances.where.not(started_at: nil).count # 出勤日数の取得。
    @superior = User.where(superior: true).where.not(id: @user.id) # 上長の取得。
    @overwork_notice_sum = Attendance.includes(:user).where(overwork_stamp_select_superior: @user.id,
                                                            overwork_stamp_confirm_step: "申請中").count # 残業通知件数の取得。
    @change_attendance_notice_sum = Attendance.includes(:user).where(change_attendance_stamp_select_superior: @user.id,
                                                                     change_attendance_stamp_confirm_step: "申請中").count # 勤怠変更通知件数の取得。
    @month_notice_sum = Attendance.includes(:user).where(month_stamp_select_superior: @user.id,
                                                         month_stamp_confirm_step: "申請中").count # １ヶ月分勤怠申請の通知件数の取得。
    respond_to do |format| # csv出力
      format.html 
      format.csv do |csv|
        send_attndances_csv(@attendances)
      end
    end
  end

  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      log_in @user
      flash[:success] = '新規作成に成功しました。'
      redirect_to @user
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @user.update_attributes(user_params)
      flash[:success] = "ユーザー情報を更新しました。"
      if current_user.admin?
        redirect_to users_url
      else
        redirect_to @user
      end
    else
      if current_user.admin?
        redirect_to users_url
      else
        render :edit
      end
    end
  end

  def destroy
    @user.destroy
    flash[:success] = "#{@user.name}のデータを削除しました。"
    redirect_to users_url
  end

  def search
    @results = @q.result.where.not(admin: true)
  end

  def edit_basic_info
  end

  def update_basic_info
    @users = User.all
    @users.each do |user|
      if user.update_attributes(basic_info_params)
        flash[:success] = "全ユーザーの基本情報を更新しました。"
      else
        flash[:danger] = "基本情報の更新は失敗しました。<br>" + user.errors.full_messages.join("<br>")
      end
    end
    redirect_to users_url
  end
  
  def attendance_at_work_employees
    @users = User.includes(:attendances)
                 .where(attendances: {worked_on: Date.today, finished_at: nil})
                 .where.not(attendances: {started_at: nil})
  end

  def csv_import
    if params[:file].blank?
      flash[:danger]= "csvファイルが未選択です。選択してください。"
    else
      User.import(params[:file])
      flash[:success] = "csvファイルのインポートに成功しました。"
    end
    redirect_to users_url
  end

  private
  
    def set_q
      @q = User.ransack(params[:q])
    end

    def user_params
      params.require(:user).permit(:name,
                                   :email,
                                   :affiliation,
                                   :employee_number,
                                   :uid,
                                   :basic_work_time,
                                   :designated_work_start_time,
                                   :designated_work_end_time,
                                   :password,
                                   :password_confirmation)
    end

    def basic_info_params
      params.require(:user).permit(:basic_time, :work_time)
    end

    def send_attndances_csv(attendances)
      bom = "\uFEFF" #文字化け防止。
      csv_data = CSV.generate(bom, encoding: Encoding::SJIS, row_sep: "\r\n", force_quotes: true) do |csv| # 対象データをCSV形式に自動変換。
        column_names = %w(日付 曜日 出勤時間 退勤時間) # 空白で区切って配列を返す。
        csv << column_names # 表の列に入る名前を定義。
        @attendances = @user.attendances.where(worked_on: @first_day..@last_day).order(:worked_on)
        @attendances.each do |day|
          column_values = [
            l(day.worked_on, format: :short),
            $days_of_the_week[day.worked_on.wday],
            if day.started_at.present? || (day.change_attendance_stamp_confirm_step == "承認").present?
              l(day.started_at, format: :time)
            else
              ""
            end,
            if day.finished_at.present? || (day.change_attendance_stamp_confirm_step == "承認").present?
              l(day.finished_at, format: :time)
            else
              ""
            end
          ] # column_valuesに代入するカラム値を定義。
          csv << column_values # 表の行に入る値を定義。
        end
      end
      send_data(csv_data, filename: "#{@attendance.worked_on.year}年#{@attendance.worked_on.month}月分 #{@user.name} 勤怠一覧.csv") # csv出力のファイル名を定義。
    end
    
    # beforeフィルター

    # 管理権限者、または現在ログインしているユーザーを許可します。
    def admin_or_correct_user
      @user = User.find(params[:id]) if @user.blank?
      unless current_user?(@user) || current_user.admin?
        flash[:danger] = "アクセス権限がありません。"
        redirect_to(root_url)
      end  
    end
end
