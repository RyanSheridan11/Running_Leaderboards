class StravaToken < ApplicationRecord
  include HTTParty

  validates :access_token, :refresh_token, :expires_at, presence: true

  def expired?
    # Add 2 hours of leeway - consider token expired 2 hours before actual expiration
    Time.current >= (expires_at - 2.hours)
  end

  def self.current
    order(:created_at).last
  end

  def refresh!
    response = HTTParty.post(
      "https://www.strava.com/api/v3/oauth/token",
      body: {
        client_id: Rails.application.credentials.strava&.client_id,
        client_secret: Rails.application.credentials.strava&.client_secret,
        grant_type: "refresh_token",
        refresh_token: self.refresh_token
      }
    )

    if response.success?
      token_data = response.parsed_response
      update!(
        access_token: token_data["access_token"],
        refresh_token: token_data["refresh_token"],
        expires_at: Time.at(token_data["expires_at"]),
        expires_in: token_data["expires_in"]
      )
      self
    else
      Rails.logger.error "Failed to refresh Strava token: #{response.code} - #{response.message}"
      raise "Failed to refresh Strava token"
    end
  end
end


# curl -X POST https://www.strava.com/api/v3/oauth/token \
# -d client_id=your_id \
# -d client_secret=your_secret \
# -d grant_type=refresh_token \
# -d refresh_token=your_refresh_token
