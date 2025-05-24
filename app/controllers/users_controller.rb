class UsersController < ApplicationController
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)
    if @user.save
      session[:user_id] = @user.id
      redirect_to root_path, notice: "Account created!"
    else
      render :new
    end
  end

  def show
    @user = User.find(params[:id])
    @runs = @user.runs.order(created_at: :desc)
  end

  def profile
    redirect_to login_path unless logged_in?
    @user = current_user
    @runs = @user.runs.order(created_at: :desc)
  end

  private

  def user_params
    params.require(:user).permit(:username, :password, :password_confirmation)
  end
end
