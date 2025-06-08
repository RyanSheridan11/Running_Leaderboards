class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by_email(params[:email])
    if user.nil?
      flash.now[:alert] = "User does not exist"
      render :new, status: :unprocessable_entity
    elsif user.needs_password_setup?
      # User exists but has no password - redirect to password setup
      session[:pending_user_id] = user.id
      redirect_to setup_password_path, notice: "Please set up your password to continue"
    elsif params[:password].blank?
      flash.now[:alert] = "Password is required"
      render :new, status: :unprocessable_entity
    elsif !user.authenticate(params[:password])
      flash.now[:alert] = "Wrong password"
      render :new, status: :unprocessable_entity
    else
      session[:user_id] = user.id
      redirect_to root_path, notice: "Logged in!"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to login_path, notice: "Logged out!"
  end

  def setup_password
    @user = User.find_by(id: session[:pending_user_id])
    if @user.nil?
      redirect_to login_path, alert: "Invalid session. Please try logging in again."
    end
  end

  def create_password
    @user = User.find_by(id: session[:pending_user_id])
    if @user.nil?
      redirect_to login_path, alert: "Invalid session. Please try logging in again."
      return
    end

    if params[:password].blank?
      flash.now[:alert] = "Password cannot be blank"
      render :setup_password, status: :unprocessable_entity
      return
    end

    if params[:password] != params[:password_confirmation]
      flash.now[:alert] = "Password confirmation doesn't match"
      render :setup_password, status: :unprocessable_entity
      return
    end

    if params[:password].length < 4
      flash.now[:alert] = "Password must be at least 4 characters long"
      render :setup_password, status: :unprocessable_entity
      return
    end

    @user.password = params[:password]
    @user.password_confirmation = params[:password_confirmation]

    if @user.save
      session[:user_id] = @user.id
      session[:pending_user_id] = nil
      redirect_to root_path, notice: "Password set successfully! Welcome to the running leaderboard!"
    else
      flash.now[:alert] = "There was an error setting your password. Please try again."
      render :setup_password, status: :unprocessable_entity
    end
  end
end
