class Admin::PlaysController < ApplicationController
  before_action :require_admin
  before_action :set_play, only: [:show, :approve, :reject, :destroy]

  def index
    @pending_plays = Play.where(status: 'pending').order(created_at: :desc)
    @approved_plays = Play.where(status: 'approved').order(created_at: :desc)
    @rejected_plays = Play.where(status: 'rejected').order(created_at: :desc)
  end

  def show
  end

  def approve
    @play.update(status: 'approved')
    redirect_to admin_plays_path, notice: 'Play approved successfully!'
  end

  def reject
    @play.update(status: 'rejected')
    redirect_to admin_plays_path, notice: 'Play rejected.'
  end

  def destroy
    @play.destroy
    redirect_to admin_plays_path, notice: 'Play deleted successfully!'
  end

  private

  def set_play
    @play = Play.find(params[:id])
  end

  def require_admin
    redirect_to root_path unless current_user&.admin?
  end
end
