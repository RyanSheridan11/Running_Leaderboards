class Admin::RunsController < ApplicationController
  before_action :require_login
  before_action :require_admin

  def index
    @runs = Run.includes(:user).order(created_at: :desc)
    @runs = @runs.where(race_type: params[:race_type]) if params[:race_type].present?
  end

  def destroy
    @run = Run.find(params[:id])
    @run.destroy
    redirect_to admin_runs_path, notice: "Run deleted successfully."
  end
end
