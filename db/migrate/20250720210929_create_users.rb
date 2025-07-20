class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users do |t|
      t.string :pin, null: false
      t.datetime :last_synced_at

      t.timestamps
    end
    add_index :users, :pin, unique: true
  end
end
