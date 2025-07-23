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
    # Check if series already exists in the system
    series = Series.find_by(tvdb_id: series_id)
    is_new_series = series.nil?

    if is_new_series
      # Get detailed series information for new series
      series_details = @client.get_series_details(series_id)
      series_name = series_details["name"] || "Unknown Series"

      broadcast_sync_progress(current, total, "Syncing new series: #{series_name}...")

      # Create new series record (normalized schema)
      series = Series.create!(
        tvdb_id: series_id,
        name: series_details["name"],
        imdb_id: series_details["remoteIds"]&.find { |r| r["sourceName"] == "IMDB" }&.dig("id"),
        last_synced_at: Time.current
      )
    else
      # For existing series, check if it needs sync (series + episodes)
      if series.needs_sync?
        broadcast_sync_progress(current, total, "Syncing series: #{series.name}...")
      else
        broadcast_sync_progress(current, total, "Skipping recent sync: #{series.name}")
        # Just ensure user association exists and skip all syncing
        begin
          @user.user_series.find_or_create_by!(series: series)
        rescue ActiveRecord::RecordNotUnique
          # Association already exists, continue
        end
        return
      end
    end

    # Associate series with user (handles race conditions gracefully)
    begin
      @user.user_series.find_or_create_by!(series: series)
    rescue ActiveRecord::RecordNotUnique
      # Association already exists, continue
    end

    # Sync episodes using shared service (only if new series or needs sync)
    # For existing series, we may need series details for episode processing
    # Only fetch if we didn't already get it for a new series
    series_details = defined?(series_details) ? series_details : nil

    episode_sync_service = EpisodeSyncService.new(@client)
    episode_sync_service.sync_episodes_for_series(series, series_details)

    # Mark series as synced since we just processed it (new series already have timestamp set)
    series.mark_as_synced! unless is_new_series
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
