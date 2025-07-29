ActiveAdmin.register User do
  menu priority: 1
  permit_params :pin, :last_synced_at

  member_action :sync, method: :post do
    UserSyncIndividualJob.perform_later(resource.pin, force: true)
    redirect_to resource_path(resource), notice: "Sync job queued for user #{resource.pin}"
  end

  index do
    selectable_column
    id_column
    column :pin
    column :last_synced_at
    column :series_count do |user|
      user.series.count
    end
    column :needs_sync? do |user|
      status_tag(user.needs_sync? ? "Yes" : "No", class: user.needs_sync? ? "error" : "ok")
    end
    column :created_at
    actions do |user|
      link_to "Sync", sync_admin_user_path(user), method: :post, class: "member_link", confirm: "Queue sync job for this user?"
    end
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
        status_tag(user.needs_sync? ? "Yes" : "No", class: user.needs_sync? ? "error" : "ok")
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

    panel "Actions" do
      link_to "Trigger Sync", sync_admin_user_path(user), method: :post, class: "button", confirm: "Queue sync job for this user?"
    end
  end
end
