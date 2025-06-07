class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  helper_method :current_user, :logged_in?, :admin?

  before_action :check_password_setup

  private

  def current_user
    @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
  end

  def logged_in?
    !!current_user
  end

  def admin?
    logged_in? && current_user.admin?
  end

  def require_login
    unless logged_in?
      redirect_to login_path, alert: "You must be logged in to access this section."
    end
  end

  def require_admin
    unless admin?
      redirect_to root_path, alert: "You must be an admin to access this section."
    end
  end

  def check_password_setup
    return unless logged_in?
    return if controller_name == "sessions" # Don't redirect from sessions controller

    if current_user.needs_password_setup?
      session[:pending_user_id] = current_user.id
      session[:user_id] = nil  # Log them out until password is set
      redirect_to setup_password_path, alert: "Please set up your password to continue."
    end
  end
end
