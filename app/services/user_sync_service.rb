class UserSyncService
  def initialize(user)
    @user = user
    @client = TvdbClient.new
  end

  def call
    Rails.logger.info "UserSyncService: Starting sync for user ID #{@user.id}"

    # Authenticate with the user's PIN
    @client.authenticate(@user.pin)

    # Get user's favorite series
    favorites = @client.get_user_favorites
    total_series = favorites.length

    Rails.logger.info "UserSyncService: Found #{total_series} favorite series for user ID #{@user.id}"

    # Broadcast sync start
    broadcast_sync_progress(0, total_series, "Starting sync...")

    favorites.each_with_index do |series_id, index|
      begin
        sync_series(series_id, index + 1, total_series)
      rescue => e
        Rails.logger.error "UserSyncService: Failed to sync series #{series_id}: #{e.message}"
        broadcast_sync_progress(index + 1, total_series, "Error syncing series: #{e.message}")
      end
    end

    # Mark user as synced
    @user.mark_as_synced!

    # Broadcast completion
    broadcast_sync_progress(total_series, total_series, "Sync completed!")

    Rails.logger.info "UserSyncService: Completed sync for user ID #{@user.id}"
  end

  private

  def sync_series(series_id, current, total)
    # Get detailed series information first to show series name
    series_details = @client.get_series_details(series_id)
    series_name = series_details["name"] || "Unknown Series"

    broadcast_sync_progress(current, total, "Syncing: #{series_name}...")

    # Find or create series record
    series = @user.series.find_or_initialize_by(tvdb_id: series_id)
    series.assign_attributes(
      name: series_details["name"],
      imdb_id: series_details["remoteIds"]&.find { |r| r["sourceName"] == "IMDB" }&.dig("id")
    )
    series.save!

    # Get episodes for this series
    episodes_data = @client.get_series_episodes(series_id)

    # Sync episodes
    episodes_data.each do |episode_data|
      next unless episode_data["aired"] && episode_data["seasonNumber"] && episode_data["number"]

      episode = series.episodes.find_or_initialize_by(
        season_number: episode_data["seasonNumber"],
        episode_number: episode_data["number"]
      )

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

  def broadcast_sync_progress(current, total, message)
    percentage = total > 0 ? (current.to_f / total * 100).round : 0

    Rails.logger.info "UserSyncService: Broadcasting progress - #{percentage}% (#{current}/#{total}) - #{message}"

    ActionCable.server.broadcast(
      "sync_#{@user.pin}",
      {
        current: current,
        total: total,
        percentage: percentage,
        message: message
      }
    )

    Rails.logger.info "UserSyncService: Broadcast sent to channel sync_#{@user.pin}"
  end

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
        Rails.logger.warn "UserSyncService: Failed to parse air time '#{air_time}' for episode: #{e.message}"
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
        Rails.logger.warn "UserSyncService: Failed to parse default air time '#{default_air_time}': #{e.message}"
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
    return "20:00" if network&.match?/(HBO|Showtime|FX|AMC)/i  # Premium/cable often 8 PM
    return "21:00" if network&.match?/(CBS|NBC|ABC|FOX)/i      # Broadcast often 9 PM
    
    # General default
    "20:00" # 8 PM
  end

  def guess_timezone_from_network(network)
    # Map common networks to their typical timezones
    case network.to_s.upcase
    when /HBO|SHOWTIME|MTV|VH1|COMEDY CENTRAL|FX|AMC/
      "America/New_York"  # East Coast
    when /FOX|ABC|CBS|NBC|CW/
      "America/New_York"  # Major networks typically reference Eastern
    when /DISNEY|NICKELODEON/
      "America/New_York"
    else
      nil # Let caller use default
    end
  end
end
