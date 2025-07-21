class AddAirTimeAndRuntimeToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :air_time, :datetime
    add_column :episodes, :runtime_minutes, :integer
    add_column :episodes, :original_timezone, :string
    add_column :episodes, :air_datetime_utc, :datetime
    
    add_index :episodes, :air_datetime_utc
  end
end