class AddLastSyncedAtToSeries < ActiveRecord::Migration[8.0]
  def change
    add_column :series, :last_synced_at, :datetime
  end
end
