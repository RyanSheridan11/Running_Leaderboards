class VotesController < ApplicationController
  before_action :require_login
  before_action :get_play_pair, only: [ :index, :update ]

  def index
    # Prepare list of events for filtering and render voting page
    @events = Event.all
  end

  def update
    # Record single head-to-head vote
    selected_id = params[:selected_play_id]
    if selected_id.present?
      chosen = Play.find(params[:selected_play_id])
      other  = (@play_pair - [ chosen ]).first

      changes = chosen.update_elo_against(other)

      redirect_to vote_path, notice: changes
    else
      redirect_to vote_path, alert: "Please select a play to vote."
    end
  end

  private

  def get_play_pair
    base_scope = Play.approved.includes(:user)
    if action_name == "index"
      @selected_event_id = params[:event_id]
      base_scope = base_scope.where(event_id: @selected_event_id) if @selected_event_id.present?
      @play_pair = base_scope.order(Arel.sql("RANDOM()")).limit(2)
    else
      # pull the same IDs back from the form for update
      ids = params.require(:play_ids).split(",").map(&:to_i)
      @play_pair = Play.find(ids)
    end
  end
end
