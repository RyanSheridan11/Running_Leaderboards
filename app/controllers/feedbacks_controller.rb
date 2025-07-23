class FeedbacksController < ApplicationController
  before_action :require_login
  before_action :require_admin, except: [ :index, :show ]
  before_action :check_feedback_access, only: [ :index, :show ]
  before_action :set_feedback, only: [ :show, :edit, :update, :destroy ]
  before_action :set_user, only: [ :new, :create ]

  def index
    if params[:user_id]
      @user = User.find(params[:user_id])
      @feedbacks = @user.feedbacks.includes(:event).recent
    else
      # Admin view of all feedback
      @feedbacks = Feedback.includes(:user, :event).recent
      @users = User.order(:firstname, :lastname)
    end
  end

  def show
  end

  def new
    @feedback = @user.feedbacks.build
    @events = Event.all
  end

  def create
    @feedback = @user.feedbacks.build(feedback_params)

    if @feedback.save
      redirect_to user_feedbacks_path(@user), notice: "Feedback was successfully created."
    else
      @events = Event.all
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @events = Event.all
  end

  def update
    if @feedback.update(feedback_params)
      redirect_to user_feedbacks_path(@feedback.user), notice: "Feedback was successfully updated."
    else
      @events = Event.all
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    user = @feedback.user
    @feedback.destroy
    redirect_to user_feedbacks_path(user), notice: "Feedback was successfully deleted."
  end

  private

  def set_feedback
    @feedback = Feedback.find(params[:id])
  end

  def set_user
    @user = User.find(params[:user_id])
  end

  def feedback_params
    params.require(:feedback).permit(:content, :event_id)
  end

  def require_admin
    redirect_to root_path, alert: "You must be an admin to access this section." unless current_user&.admin?
  end

  def check_feedback_access
    # Allow admin to see all feedback
    return if current_user&.admin?

    # Allow users to see their own feedback when viewing user-specific feedback
    if params[:user_id]
      @user = User.find(params[:user_id])
      redirect_to root_path, alert: "You must be an admin to access this section." unless current_user == @user
    else
      # Non-admin users can't see all feedback
      redirect_to root_path, alert: "You must be an admin to access this section."
    end
  end
end
