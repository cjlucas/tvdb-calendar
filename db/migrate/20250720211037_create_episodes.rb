class CreateEpisodes < ActiveRecord::Migration[8.0]
  def change
    create_table :episodes do |t|
      t.references :series, null: false, foreign_key: true
      t.string :title, null: false
      t.integer :season_number, null: false
      t.integer :episode_number, null: false
      t.date :air_date, null: false
      t.boolean :is_season_finale, default: false

      t.timestamps
    end

    add_index :episodes, [ :series_id, :season_number, :episode_number ], unique: true
    add_index :episodes, :air_date
  end
end
