class AddIndexToSeriesLastSyncedAt < ActiveRecord::Migration[8.0]
  def change
    add_index :series, :last_synced_at
  end
end
