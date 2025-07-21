class NormalizeSeriesSchema < ActiveRecord::Migration[8.0]
  def up
    # Create join table for users and series
    create_table :user_series do |t|
      t.references :user, null: false, foreign_key: true
      t.references :series, null: false, foreign_key: true
      t.timestamps
    end

    # Add unique constraint to prevent duplicate user-series associations
    add_index :user_series, [ :user_id, :series_id ], unique: true

    # Migrate existing data: populate user_series join table
    execute <<-SQL
      INSERT INTO user_series (user_id, series_id, created_at, updated_at)
      SELECT user_id, id, created_at, updated_at FROM series
    SQL

    # Remove foreign key constraint from series to users
    remove_foreign_key :series, :users

    # Remove user_id column from series
    remove_column :series, :user_id, :integer

    # Remove the old composite unique index (user_id, tvdb_id)
    remove_index :series, [ :user_id, :tvdb_id ] if index_exists?(:series, [ :user_id, :tvdb_id ])

    # Add unique constraint on tvdb_id to prevent duplicate series
    add_index :series, :tvdb_id, unique: true
  end

  def down
    # Add user_id back to series (nullable initially for safe rollback)
    add_column :series, :user_id, :integer

    # Restore foreign key
    add_foreign_key :series, :users

    # Migrate data back: set user_id from first association in join table
    execute <<-SQL
      UPDATE series#{' '}
      SET user_id = (
        SELECT user_id#{' '}
        FROM user_series#{' '}
        WHERE user_series.series_id = series.id#{' '}
        LIMIT 1
      )
    SQL

    # Remove the tvdb_id unique index
    remove_index :series, :tvdb_id if index_exists?(:series, :tvdb_id)

    # Add back the composite index
    add_index :series, [ :user_id, :tvdb_id ], unique: true

    # Drop the join table
    drop_table :user_series
  end
end
