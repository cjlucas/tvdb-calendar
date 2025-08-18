class AddOverviewToEpisodes < ActiveRecord::Migration[8.0]
  def change
    add_column :episodes, :overview, :text
  end
end
