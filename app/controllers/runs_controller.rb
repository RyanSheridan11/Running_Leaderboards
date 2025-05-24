class RunsController < ApplicationController
  before_action :require_login, only: [:new, :create]

  def index
    @runs = Run.includes(:user).order(:time)
  end

  def new
    @run = Run.new
  end

  def create
    @run = current_user.runs.build(run_params)
    if @run.save
      redirect_to root_path, notice: "Run added!"
    else
      render :new
    end
  end

  private

  def run_params
    params.require(:run).permit(:date, :time)
  end
end
