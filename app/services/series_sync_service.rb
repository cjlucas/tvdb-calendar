class SeriesSyncService
  # Network timezone mappings for common TV networks
  # Based on typical broadcast timezones and network headquarters
  # Update this hash when adding support for new networks or regions
  NETWORK_TIMEZONE_MAPPINGS = {
    # Premium Cable Networks (East Coast based)
    %w[HBO SHOWTIME STARZ EPIX] => "America/New_York",

    # Cable Networks (East Coast based)
    %w[MTV VH1 FX AMC TNT TBS USA SYFY] => "America/New_York",
    [ "COMEDY CENTRAL" ] => "America/New_York",

    # Major Broadcast Networks (Eastern time reference)
    %w[FOX ABC CBS NBC CW PBS] => "America/New_York",

    # Children's Networks
    %w[DISNEY NICKELODEON CARTOON] => "America/New_York",

    # Streaming Services (typically use Eastern for premieres)
    %w[NETFLIX HULU AMAZON PRIME] => "America/New_York"
  }.freeze

  def initialize(client = nil)
    @client = client || TvdbClient.new
  end

  def sync_series_data(series)
    # Get updated series details
    series_details = @client.get_series_details(series.tvdb_id)

    # Update series information
    series.update!(
      name: series_details["name"],
      imdb_id: series_details["remoteIds"]&.find { |r| r["sourceName"] == "IMDB" }&.dig("id")
    )

    # Sync episodes for this series
    sync_episodes_for_series(series, series_details)
  end

  def sync_episodes_for_series(series, series_details = nil)
    # Get series details if not provided
    series_details ||= @client.get_series_details(series.tvdb_id)

    # Get episodes for this series
    episodes_data = @client.get_series_episodes(series.tvdb_id)

    # Load all existing episodes for this series to avoid N+1 queries
    existing_episodes = series.episodes.index_by { |ep| [ ep.season_number, ep.episode_number ] }

    # Sync episodes
    episodes_data.each do |episode_data|
      next unless episode_data["aired"] && episode_data["seasonNumber"] && episode_data["number"]

      # Use in-memory lookup instead of database query
      episode_key = [ episode_data["seasonNumber"], episode_data["number"] ]
      episode = existing_episodes[episode_key]

      if episode.nil?
        # Create new episode
        episode = series.episodes.build(
          season_number: episode_data["seasonNumber"],
          episode_number: episode_data["number"]
        )
        existing_episodes[episode_key] = episode
      end

      # Parse air time and timezone information if available
      air_datetime_utc = parse_air_datetime(episode_data, series_details)

      episode.assign_attributes(
        title: episode_data["name"] || "Episode #{episode_data['number']}",
        air_date: Date.parse(episode_data["aired"]),
        is_season_finale: episode_data["finaleType"] == "season" || episode_data["finaleType"] == "series",
        air_datetime_utc: air_datetime_utc,
        runtime_minutes: extract_runtime(episode_data, series_details),
        original_timezone: extract_timezone(episode_data, series_details)
      )

      episode.save!
    end
  end

  private

  def parse_air_datetime(episode_data, series_details)
    # Try to extract air time from various possible fields
    air_time = episode_data["airTime"] || episode_data["airsTime"] || episode_data["originalAirTime"]
    air_date = episode_data["aired"]

    return nil unless air_date.present?

    if air_time.present?
      # Combine date and time
      begin
        base_date = Date.parse(air_date)
        # Handle various time formats that TVDB might use
        time_str = "#{base_date} #{air_time}"

        # Determine the source timezone
        source_timezone = extract_timezone(episode_data, series_details) || "America/New_York"

        # Parse in the source timezone and convert to UTC
        source_tz = Time.find_zone(source_timezone)
        local_time = source_tz.parse(time_str)
        return local_time.utc if local_time
      rescue => e
        Rails.logger.warn "SeriesSyncService: Failed to parse air time '#{air_time}' for episode: #{e.message}"
      end
    end

    # Fallback: use a default time if no specific time is available
    # Many shows air at 8 PM in their local timezone
    default_air_time = extract_default_air_time(series_details)
    if default_air_time.present?
      begin
        base_date = Date.parse(air_date)
        source_timezone = extract_timezone(episode_data, series_details) || "America/New_York"

        source_tz = Time.find_zone(source_timezone)
        default_datetime = source_tz.parse("#{base_date} #{default_air_time}")
        return default_datetime.utc if default_datetime
      rescue => e
        Rails.logger.warn "SeriesSyncService: Failed to parse default air time '#{default_air_time}': #{e.message}"
      end
    end

    nil
  end

  def extract_runtime(episode_data, series_details)
    # Try episode-specific runtime first
    runtime = episode_data["runtime"] || episode_data["runTime"] || episode_data["length"]

    # Fall back to series default runtime
    runtime ||= series_details["averageRuntime"] || series_details["runtime"] || series_details["averageLength"]

    # Convert to integer if it's a string
    runtime = runtime.to_i if runtime.is_a?(String) && runtime.match?(/^\d+$/)

    runtime if runtime.is_a?(Integer) && runtime > 0
  end

  def extract_timezone(episode_data, series_details)
    # Try to extract timezone information from various sources
    timezone = episode_data["timezone"] || episode_data["timeZone"]
    timezone ||= series_details["timezone"] || series_details["timeZone"]

    # Check if series has network information that might indicate timezone
    if series_details["originalNetwork"].present?
      network = series_details["originalNetwork"]
      timezone ||= guess_timezone_from_network(network)
    end

    # Default to EST/EDT since many US shows use this
    timezone || "America/New_York"
  end

  def extract_default_air_time(series_details)
    # Try to extract default air time from series details
    air_time = series_details["airTime"] || series_details["airsTime"] || series_details["originalAirTime"]
    return air_time if air_time.present?

    # Some common defaults based on network patterns
    network = series_details["originalNetwork"]
    return "20:00" if network&.match?(/(HBO|Showtime|FX|AMC)/i)  # Premium/cable often 8 PM
    return "21:00" if network&.match?(/(CBS|NBC|ABC|FOX)/i)      # Broadcast often 9 PM

    # General default
    "20:00" # 8 PM
  end

  def guess_timezone_from_network(network)
    return nil if network.blank?

    # Find matching timezone from network mappings
    network_upper = network.to_s.upcase

    NETWORK_TIMEZONE_MAPPINGS.each do |networks, timezone|
      if networks.any? { |net| network_upper.include?(net) }
        return timezone
      end
    end

    nil # Let caller use default
  end
end
