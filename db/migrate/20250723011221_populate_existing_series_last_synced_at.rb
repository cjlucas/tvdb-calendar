class PopulateExistingSeriesLastSyncedAt < ActiveRecord::Migration[8.0]
  def up
    # Set last_synced_at to a time in the past for existing series
    # This ensures they won't all be synced immediately by user sync jobs
    # but will still be eligible for sync within a reasonable timeframe
    Series.where(last_synced_at: nil).update_all(last_synced_at: 6.hours.ago)
  end

  def down
    # Revert existing series back to nil
    Series.update_all(last_synced_at: nil)
  end
end
