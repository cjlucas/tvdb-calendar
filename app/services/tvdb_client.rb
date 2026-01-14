class InvalidPinError < StandardError; end

class TvdbClient
  include HTTParty
  base_uri "https://api4.thetvdb.com/v4"

  def initialize(api_key = nil)
    @api_key = api_key || ENV["TVDB_API_KEY"]
    raise ArgumentError, "TVDB API key is required" unless @api_key
  end

  def authenticate(pin)
    response = self.class.post("/login",
      body: {
        apikey: @api_key,
        pin: pin
      }.to_json,
      headers: { "Content-Type" => "application/json" }
    )

    if response.success?
      @token = response.parsed_response["data"]["token"]
      @token
    else
      # Check if this is specifically an invalid PIN error
      if response.code == 401 && (
        response.parsed_response&.dig("message")&.match?(/\bpin\b/i) ||
        response.parsed_response&.dig("error")&.match?(/invalid.*pin|pin.*invalid/i)
      )
        raise InvalidPinError, "PIN Invalid"
      else
        raise "Authentication failed: #{response.parsed_response['message']}"
      end
    end
  end

  def get_user_favorites
    raise "Not authenticated" unless @token

    response = self.class.get("/user/favorites",
      headers: auth_headers
    )

    if response.success?
      data = response.parsed_response["data"]
      # Return array of series IDs, or empty array if none
      data["series"] || []
    else
      raise "Failed to fetch favorites: #{response.parsed_response['message']}"
    end
  end

  def get_series_details(series_id)
    raise "Not authenticated" unless @token

    response = self.class.get("/series/#{series_id}/extended",
      headers: auth_headers
    )

    if response.success?
      response.parsed_response["data"]
    else
      raise "Failed to fetch series details: #{response.parsed_response['message']}"
    end
  end

  def get_series_episodes(series_id, season = nil)
    raise "Not authenticated" unless @token

    url = "/series/#{series_id}/episodes/default"
    url += "?season=#{season}" if season

    all_episodes = []
    page = 0

    loop do
      page_url = "#{url}#{season ? '&' : '?'}page=#{page}"
      response = self.class.get(page_url, headers: auth_headers)

      if response.success?
        data = response.parsed_response["data"]
        all_episodes.concat(data["episodes"] || [])

        # Check if there are more pages using top-level links
        links = response.parsed_response["links"]
        total_items = links&.dig("total_items") || 0
        page_size = links&.dig("page_size") || 500
        total_pages = (total_items.to_f / page_size).ceil

        break if page >= total_pages - 1
        page += 1
      else
        raise "Failed to fetch episodes: #{response.parsed_response['message']}"
      end
    end

    all_episodes
  end

  def get_episode_details(episode_id)
    raise "Not authenticated" unless @token

    response = self.class.get("/episodes/#{episode_id}/extended",
      headers: auth_headers
    )

    if response.success?
      response.parsed_response["data"]
    else
      raise "Failed to fetch episode details: #{response.parsed_response['message']}"
    end
  end

  private

  def auth_headers
    {
      "Authorization" => "Bearer #{@token}",
      "Content-Type" => "application/json"
    }
  end
end
