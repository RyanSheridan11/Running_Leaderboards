class Admin::UsersController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user, only: [ :promote_admin, :demote_admin, :destroy ]

  def index
    @users = User.includes(:runs).order(:firstname)
  end

  def promote_admin
    if @user.update(admin: true)
      redirect_to admin_users_path, notice: "#{@user.full_name} has been promoted to admin."
    else
      redirect_to admin_users_path, alert: "Failed to promote #{@user.full_name} to admin."
    end
  end

  def demote_admin
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot demote yourself."
      return
    end

    if @user.update(admin: false)
      redirect_to admin_users_path, notice: "#{@user.full_name} has been demoted from admin."
    else
      redirect_to admin_users_path, alert: "Failed to demote #{@user.full_name} from admin."
    end
  end

  def destroy
    if @user == current_user
      redirect_to admin_users_path, alert: "You cannot delete your own account."
      return
    end

    user_name = @user.full_name
    runs_count = @user.runs.count

    if @user.destroy
      redirect_to admin_users_path, notice: "#{user_name} and their #{runs_count} run(s) have been deleted."
    else
      redirect_to admin_users_path, alert: "Failed to delete #{user_name}."
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end
end
