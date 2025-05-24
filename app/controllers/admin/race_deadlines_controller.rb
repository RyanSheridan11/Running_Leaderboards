class Admin::RaceDeadlinesController < ApplicationController
  before_action :require_login
  before_action :require_admin
  before_action :set_race_deadline, only: [:show, :edit, :update, :destroy]

  def index
    @race_deadlines = RaceDeadline.order(due_date: :desc)
  end

  def show
    @users_with_submissions = @race_deadline.users_with_submissions.includes(:runs)
    @users_without_submissions = @race_deadline.users_without_submissions
  end

  def new
    @race_deadline = RaceDeadline.new
  end

  def create
    @race_deadline = RaceDeadline.new(race_deadline_params)
    
    if @race_deadline.save
      redirect_to admin_race_deadlines_path, notice: "Race deadline created successfully."
    else
      render :new
    end
  end

  def edit
  end

  def update
    if @race_deadline.update(race_deadline_params)
      redirect_to admin_race_deadlines_path, notice: "Race deadline updated successfully."
    else
      render :edit
    end
  end

  def destroy
    @race_deadline.destroy
    redirect_to admin_race_deadlines_path, notice: "Race deadline deleted successfully."
  end

  private

  def set_race_deadline
    @race_deadline = RaceDeadline.find(params[:id])
  end

  def race_deadline_params
    params.require(:race_deadline).permit(:race_type, :due_date, :description, :active)
  end
end
