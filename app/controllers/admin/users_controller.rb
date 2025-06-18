class Admin::UsersController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_user, only: [ :promote_admin, :demote_admin, :destroy, :update_user_type ]

  def index
    @users = User.includes(:runs).order(:firstname)

    # Filter by user type if specified
    if params[:user_type].present?
      @users = @users.where(user_type: params[:user_type])
    end
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

  def update_user_type
    if @user.update(user_type: params[:user_type])
      redirect_to admin_users_path, notice: "#{@user.full_name} has been updated to #{params[:user_type].titleize}."
    else
      redirect_to admin_users_path, alert: "Failed to update #{@user.full_name}'s user type."
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
