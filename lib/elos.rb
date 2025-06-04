# frozen_string_literal: true

module Elos
  # A head-to-head match for calculating Elo rating updates.
  class Match
    # Initialize a new Match.
    # @param k [Numeric] the K-factor used for rating adjustments (default: 24)
    def initialize(k: 24)
      @k = k
      @players = []
    end

    # Add a player to the match.
    # @param rating [Numeric] the current Elo rating of the player
    # @param winner [Boolean] whether this player won the match (default: false)
    def add_player(rating:, winner: false)
      @players << { rating: rating.to_f, winner: winner }
    end

    # Compute and return the new Elo ratings for the players in the order they were added.
    # @return [Array<Integer>] updated ratings for each player
    def updated_ratings
      unless @players.size == 2
        raise ArgumentError, "Match requires exactly two players"
      end

      winners = @players.count { |p| p[:winner] }
      unless winners == 1
        raise ArgumentError, "Match requires exactly one winner"
      end

      p1, p2 = @players
      new1 = compute_new_rating(p1, p2)
      new2 = compute_new_rating(p2, p1)

      [new1.round, new2.round]
    end

    private

    # Calculate the new rating for a player given their opponent.
    def compute_new_rating(player, opponent)
      player_rating = player[:rating]
      opponent_ranking = opponent[:rating]
      expected = 1.0 / (1 + 10**((opponent_ranking - player_rating) / 400.0))
      actual = player[:winner] ? 1.0 : 0.0
      player_rating + @k * (actual - expected)
    end
  end
end
