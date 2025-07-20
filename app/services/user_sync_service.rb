class UserSyncService
  def initialize(user)
    @user = user
    @client = TvdbClient.new
  end

  def call
    Rails.logger.info "UserSyncService: Starting sync for user #{@user.pin}"
    
    # Authenticate with the user's PIN
    @client.authenticate(@user.pin)
    
    # Get user's favorite series
    favorites = @client.get_user_favorites
    total_series = favorites.length
    
    Rails.logger.info "UserSyncService: Found #{total_series} favorite series for user #{@user.pin}"
    
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
    
    Rails.logger.info "UserSyncService: Completed sync for user #{@user.pin}"
  end

  private

  def sync_series(series_id, current, total)
    broadcast_sync_progress(current, total, "Syncing series #{series_id}...")
    
    # Get detailed series information
    series_details = @client.get_series_details(series_id)
    
    # Find or create series record
    series = @user.series.find_or_initialize_by(tvdb_id: series_id)
    series.assign_attributes(
      name: series_details['name'],
      imdb_id: series_details['remoteIds']&.find { |r| r['sourceName'] == 'IMDB' }&.dig('id')
    )
    series.save!
    
    # Get episodes for this series
    episodes_data = @client.get_series_episodes(series_id)
    
    # Sync episodes
    episodes_data.each do |episode_data|
      next unless episode_data['aired'] && episode_data['seasonNumber'] && episode_data['number']
      
      episode = series.episodes.find_or_initialize_by(
        season_number: episode_data['seasonNumber'],
        episode_number: episode_data['number']
      )
      
      episode.assign_attributes(
        title: episode_data['name'] || "Episode #{episode_data['number']}",
        air_date: Date.parse(episode_data['aired']),
        is_season_finale: episode_data['finaleType'] == 'season' || episode_data['finaleType'] == 'series'
      )
      
      episode.save!
    end
    
    broadcast_sync_progress(current, total, "Completed series: #{series.name}")
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
end