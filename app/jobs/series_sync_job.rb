class SeriesSyncJob < ApplicationJob
  queue_as :default

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

    # Use a system-level authentication approach
    # Since this is a background job, we need to authenticate without a user PIN
    # We'll need to get any valid user PIN to authenticate
    sample_user = User.where.not(pin: nil).first
    return unless sample_user

    client.authenticate(sample_user.pin)

    # Get updated series details
    series_details = client.get_series_details(series.tvdb_id)

    # Update series information
    series.update!(
      name: series_details["name"],
      imdb_id: series_details["remoteIds"]&.find { |r| r["sourceName"] == "IMDB" }&.dig("id")
    )
  end
end
