class UsersController < ApplicationController
  before_action :require_login, only: [ :profile ]
  before_action :require_admin, only: [ :show ]
  def new
    @user = User.new
  end

  def create
    @user = User.new(user_params)

    begin
      if @user.save
        session[:user_id] = @user.id
        redirect_to root_path, notice: "Account created successfully! Welcome to the Running Leaderboard."
      else
        # Log validation errors for debugging
        Rails.logger.info "User creation failed: #{@user.errors.full_messages.join(', ')}"
        render :new, status: :unprocessable_entity
      end
    rescue ActiveRecord::RecordNotUnique => e
      # Handle unique constraint violations (e.g., duplicate email)
      Rails.logger.error "User creation failed due to uniqueness constraint: #{e.message}"
      @user.errors.add(:email, "is already taken")
      render :new, status: :unprocessable_entity
    rescue StandardError => e
      # Handle any other unexpected errors
      Rails.logger.error "Unexpected error during user creation: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      @user.errors.add(:base, "An unexpected error occurred. Please try again.")
      render :new, status: :unprocessable_entity
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
    permitted_params = params.require(:user).permit(:email, :password, :password_confirmation, :firstname, :lastname, :strava_username, :user_type)

    # Sanitize and normalize parameters
    permitted_params[:email] = permitted_params[:email]&.strip&.downcase
    permitted_params[:firstname] = permitted_params[:firstname]&.strip&.titleize
    permitted_params[:lastname] = permitted_params[:lastname]&.strip&.titleize
    permitted_params[:strava_username] = permitted_params[:strava_username]&.strip

    permitted_params
  rescue ActionController::ParameterMissing => e
    Rails.logger.error "Missing required parameters: #{e.message}"
    raise ActionController::BadRequest, "Required user parameters are missing"
  end
end
