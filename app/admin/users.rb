ActiveAdmin.register User do
  permit_params :pin, :last_synced_at

  index do
    selectable_column
    id_column
    column :pin
    column :last_synced_at
    column :series_count do |user|
      user.series.count
    end
    column :needs_sync? do |user|
      status_tag(user.needs_sync? ? "Yes" : "No", user.needs_sync? ? :error : :ok)
    end
    column :created_at
    actions
  end

  filter :pin
  filter :last_synced_at
  filter :created_at

  show do
    attributes_table do
      row :id
      row :pin
      row :last_synced_at
      row :created_at
      row :updated_at
      row :series_count do |user|
        user.series.count
      end
      row :needs_sync? do |user|
        status_tag(user.needs_sync? ? "Yes" : "No", user.needs_sync? ? :error : :ok)
      end
    end

    panel "Series" do
      table_for user.series.limit(10) do
        column :name do |series|
          link_to series.name, admin_series_path(series)
        end
        column :tvdb_id
        column :last_synced_at
      end
    end
  end
end
