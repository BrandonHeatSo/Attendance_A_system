class BasesController < ApplicationController

  def index
    @bases = Base.all
  end

  def new
    @base = Base.new
  end

  def create
    @base = Base.new(base_params)
    if @base.save
      flash[:success] = '新規作成に成功しました。'
      redirect_to @bases
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @base.update_attributes(base_params)
      flash[:success] = "ユーザー情報を更新しました。"
      redirect_to @bases
    else
      render :edit      
    end
  end

  def destroy
    @base.destroy
    flash[:success] = "#{@base.name}のデータを削除しました。"
    redirect_to bases
  end

  private

    def base_params
      params.require(:base).permit(:base_number, :, :base_name, :attendace_type)
    end

end
