class StravaService
  include HTTParty
  base_uri "https://www.strava.com/api/v3"

  def initialize
    @club_id = Rails.application.credentials.strava&.club_id

    if @club_id.nil?
      Rails.logger.error "Strava club_id is not configured in credentials"
      raise "Strava club_id is required but not configured"
    end

    strava_token = StravaToken.last || StravaToken.create!(
      access_token: Rails.application.credentials.strava&.access_token || raise("Strava access_token not configured"),
      refresh_token: Rails.application.credentials.strava&.refresh_token || raise("Strava refresh_token not configured"),
      expires_at: Rails.application.credentials.strava&.expires_at || raise("Strava expires_at not configured")
      )
    @access_token = strava_token.access_token
    puts "🔄 Access Token: #{@access_token}"
    puts "🔄 Token Expired?: #{strava_token.expired?}"
    puts "🔄 Expiry time: #{strava_token.expires_at}"
    puts "🔄 Time: #{Time.current}"
    if strava_token.expired?
      Rails.logger.info "Strava token expired, refreshing..."
      strava_token = strava_token.refresh!
      @access_token = strava_token.access_token
    end
    @options = { headers: { "Authorization" => "Bearer #{@access_token}" } }
  end

  def get_activities(page: 1, per_page: 5)
    query_params = { page: page, per_page: per_page }

    response = self.class.get("/clubs/#{@club_id}/activities", @options.merge(query: query_params))

    # puts "Request: #{@options.merge(query: query_params)}"
    puts "Response: #{response}"
    if response.success?
      response.parsed_response
    else
      Rails.logger.error "Strava API error: #{response.code} - #{response.message}"

      # Handle authentication errors specifically
      if response.code == 401
        error_message = "Strava authentication failed (401 Unauthorized). Token may be expired or invalid."
        Rails.logger.error error_message
        raise StandardError, error_message
      elsif response.code == 403
        error_message = "Strava access forbidden (403 Forbidden). Check permissions or rate limits."
        Rails.logger.error error_message
        raise StandardError, error_message
      elsif response.code == 429
        error_message = "Strava rate limit exceeded (429 Too Many Requests). Please try again later."
        Rails.logger.error error_message
        raise StandardError, error_message
      else
        error_message = "Strava API error: #{response.code} - #{response.message}"
        Rails.logger.error error_message
        raise StandardError, error_message
      end
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
