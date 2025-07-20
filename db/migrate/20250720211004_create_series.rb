class CreateSeries < ActiveRecord::Migration[8.0]
  def change
    create_table :series do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :tvdb_id, null: false
      t.string :name, null: false
      t.string :imdb_id

      t.timestamps
    end
    
    add_index :series, [:user_id, :tvdb_id], unique: true
  end
end
