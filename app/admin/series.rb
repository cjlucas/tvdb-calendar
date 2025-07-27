ActiveAdmin.register Series do
  menu priority: 3
  permit_params :tvdb_id, :name, :imdb_id, :last_synced_at

  index do
    selectable_column
    id_column
    column :name
    column :tvdb_id
    column :imdb_id do |series|
      if series.imdb_id.present?
        link_to series.imdb_id, series.imdb_url, target: "_blank"
      end
    end
    column :users_count do |series|
      series.users.count
    end
    column :episodes_count do |series|
      series.episodes.count
    end
    column :needs_sync? do |series|
      status_tag(series.needs_sync? ? "Yes" : "No", class: series.needs_sync? ? "error" : "ok")
    end
    column :last_synced_at
    column :created_at
    actions
  end

  filter :name
  filter :tvdb_id
  filter :imdb_id
  filter :last_synced_at
  filter :created_at

  show do
    attributes_table do
      row :id
      row :name
      row :tvdb_id
      row :imdb_id do |series|
        if series.imdb_id.present?
          link_to series.imdb_url, series.imdb_url, target: "_blank"
        end
      end
      row :last_synced_at
      row :created_at
      row :updated_at
      row :users_count do |series|
        series.users.count
      end
      row :episodes_count do |series|
        series.episodes.count
      end
      row :needs_sync? do |series|
        status_tag(series.needs_sync? ? "Yes" : "No", class: series.needs_sync? ? "error" : "ok")
      end
    end

    panel "Recent Episodes" do
      table_for series.episodes.order(air_date: :desc).limit(10) do
        column :title do |episode|
          link_to episode.title, admin_episode_path(episode)
        end
        column :episode_code
        column :air_date
        column :runtime_minutes
      end
    end

    panel "Users Following" do
      table_for series.users.limit(10) do
        column :pin do |user|
          link_to user.pin, admin_user_path(user)
        end
        column :last_synced_at
        column :created_at
      end
    end
  end
end
