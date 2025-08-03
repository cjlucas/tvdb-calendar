class AddUuidToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :uuid, :string
    add_index :users, :uuid, unique: true

    # Backfill existing users with UUID v7
    reversible do |dir|
      dir.up do
        User.find_each do |user|
          user.update!(uuid: SecureRandom.uuid_v7)
        end

        # Now make the column non-nullable
        change_column_null :users, :uuid, false
      end
    end
  end
end
