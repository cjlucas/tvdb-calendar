class SeriesSyncJob < ApplicationJob
  queue_as :default

  # Prevent multiple instances from running simultaneously
  def self.perform_later_if_unique
    # Check if job is already enqueued or running (safe for test environment)
    begin
      return false if defined?(SolidQueue::Job) &&
                     SolidQueue::Job.where(class_name: name, finished_at: nil).exists?
    rescue ActiveRecord::StatementInvalid => e
      # Handle case where SolidQueue tables don't exist (e.g., test environment)
      Rails.logger.warn "SeriesSyncJob: Could not check job uniqueness: #{e.message}"
    end

    perform_later
  end

  def perform
    series_to_sync = Series.where("last_synced_at IS NULL OR last_synced_at < ?", 12.hours.ago)

    Rails.logger.info "SeriesSyncJob: Found #{series_to_sync.count} series to sync"

    series_to_sync.find_each do |series|
      begin
        sync_series_data(series)
        series.mark_as_synced!
        Rails.logger.info "SeriesSyncJob: Successfully synced series ID #{series.id} (TVDB ID: #{series.tvdb_id})"
      rescue => e
        Rails.logger.error "SeriesSyncJob: Failed to sync series ID #{series.id} (TVDB ID: #{series.tvdb_id}): #{e.message}"
      end
    end
  end

  private

  def sync_series_data(series)
    client = TvdbClient.new

    # Get updated series details
    series_details = client.get_series_details(series.tvdb_id)

    # Update series information
    series.update!(
      name: series_details["name"],
      imdb_id: series_details["remoteIds"]&.find { |r| r["sourceName"] == "IMDB" }&.dig("id")
    )

    # Also sync episodes for this series using shared service
    episode_sync_service = EpisodeSyncService.new(client)
    episode_sync_service.sync_episodes_for_series(series, series_details)
  end
end
