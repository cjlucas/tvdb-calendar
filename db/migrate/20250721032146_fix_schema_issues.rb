class FixSchemaIssues < ActiveRecord::Migration[8.0]
  def up
    # Remove duplicate index that has incorrect name
    if index_exists?(:series, :tvdb_id, name: "index_series_on_user_id_and_tvdb_id")
      remove_index :series, name: "index_series_on_user_id_and_tvdb_id"
    end
  end

  def down
    # Re-add the index if needed (though it was incorrect)
    unless index_exists?(:series, :tvdb_id, name: "index_series_on_user_id_and_tvdb_id")
      add_index :series, :tvdb_id, name: "index_series_on_user_id_and_tvdb_id", unique: true
    end
  end
end
