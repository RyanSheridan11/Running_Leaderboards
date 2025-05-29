class SessionsController < ApplicationController
  def new
  end

  def create
    user = User.find_by(username: params[:username])
    if user.nil?
      flash.now[:alert] = "User does not exist"
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
end
