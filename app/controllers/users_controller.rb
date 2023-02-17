class UsersController < ApplicationController
  before_action :set_user, only: [:show, :edit, :update, :destroy, :edit_basic_info, :update_basic_info]
  before_action :logged_in_user, only: [:index, :search, :csv_import, :edit, :update, :destroy, :edit_basic_info, :update_basic_info, :attendance_at_work_employees]
  before_action :correct_user, only: :edit
  before_action :admin_or_correct_user, only: [:show, :update]
  before_action :admin_user, only: [:index, :search, :csv_import, :destroy, :edit_basic_info, :update_basic_info, :attendance_at_work_employees]
  before_action :set_one_month, only: :show
  before_action :set_q, only: [:index, :search]

  def index
    @users = User.paginate(page: params[:page], per_page: 5).where.not(admin: true)
  end

  def show
    @worked_sum = @attendances.where.not(started_at: nil).count
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
