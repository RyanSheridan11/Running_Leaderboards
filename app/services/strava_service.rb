class StravaService
  include HTTParty
  base_uri "https://www.strava.com/api/v3"

  def initialize
    @club_id = Rails.application.credentials.strava&.club_id

    strava_token = StravaToken.last
    @access_token = strava_token.access_token
    if strava_token.expired?
      Rails.logger.info "Strava token expired, refreshing..."
      strava_token = strava_token.refresh!
      @access_token = strava_token.access_token
    end
    @options = { headers: { "Authorization" => "Bearer #{@access_token}" } }
  end

  def get_activities(page: 1, per_page: 50)
    query_params = { page: page, per_page: per_page }

    response = self.class.get("/clubs/#{@club_id}/activities", @options.merge(query: query_params))

    puts "Response: #{response}"
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Strava API error: #{response.code} - #{response.message}"
      []
    end
  end

  def self.is_5k_run?(activity)
    return false unless activity["type"] == "Run"

    distance_km = activity["distance"] / 1000.0
    distance_km >= 4.8 && distance_km <= 5.2
  end

  def self.convert_time_to_seconds(moving_time)
    # Strava returns moving_time in seconds, we store in seconds as well
    moving_time
  end
end
