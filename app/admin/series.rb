ActiveAdmin.register Series do
  permit_params :tvdb_id, :name, :imdb_id, :last_synced_at

  filter :id
  filter :tvdb_id
  filter :name
  filter :imdb_id
  filter :created_at
  filter :updated_at
  filter :last_synced_at

  index do
    selectable_column
    id_column
    column :tvdb_id
    column :name
    column :imdb_id
    column "Episodes Count" do |series|
      series.episodes.count
    end
    column "Users Count" do |series|
      series.users.count
    end
    column :last_synced_at
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :tvdb_id
      row :name
      row :imdb_id do |series|
        if series.imdb_id.present?
          link_to series.imdb_id, series.imdb_url, target: "_blank"
        end
      end
      row :last_synced_at
      row :created_at
      row :updated_at
    end

    panel "Episodes" do
      # Handle sorting for episodes
      sort_order = case params[:order]
      when "season_number, episode_number_asc"
        "season_number ASC, episode_number ASC"
      when "season_number, episode_number_desc"
        "season_number DESC, episode_number DESC"
      when "title_asc"
        "title ASC"
      when "title_desc"
        "title DESC"
      when "air_date_asc"
        "air_date ASC"
      when "air_date_desc"
        "air_date DESC"
      when "runtime_minutes_asc"
        "runtime_minutes ASC"
      when "runtime_minutes_desc"
        "runtime_minutes DESC"
      when "air_datetime_utc_asc"
        "air_datetime_utc ASC"
      when "air_datetime_utc_desc"
        "air_datetime_utc DESC"
      else
        "air_date ASC"
      end

      episodes_collection = resource.episodes.order(sort_order)
      paginated_collection(episodes_collection.page(params[:episodes_page]).per(15), param_name: "episodes_page", download_links: false) do
        table_for(collection, sortable: true, class: "index_table") do
          column "Episode", sortable: "season_number, episode_number" do |episode|
            link_to "S#{episode.season_number}E#{episode.episode_number}", admin_episode_path(episode)
          end
          column "Title", sortable: "title" do |episode|
            episode.title
          end
          column "Air Date", sortable: "air_date" do |episode|
            episode.air_date
          end
          column "Runtime", sortable: "runtime_minutes" do |episode|
            episode.runtime_minutes
          end
          column "Air Time", sortable: "air_datetime_utc" do |episode|
            episode.air_datetime_utc&.strftime("%Y-%m-%d %H:%M UTC")
          end
        end
      end
    end

    panel "Users Following This Series" do
      # Handle sorting for users
      sort_order = case params[:order]
      when "id_asc"
        "users.id ASC"
      when "id_desc"
        "users.id DESC"
      when "created_at_asc"
        "users.created_at ASC"
      when "created_at_desc"
        "users.created_at DESC"
      else
        "users.created_at DESC"
      end

      users_collection = resource.users.order(sort_order)
      paginated_collection(users_collection.page(params[:series_users_page]).per(10), param_name: "series_users_page", download_links: false) do
        table_for(collection, sortable: true, class: "index_table") do
          column "User ID", sortable: "id" do |user|
            link_to user.id, admin_user_path(user)
          end
          column "PIN (Masked)", sortable: false do |user|
            "#{user.pin[0..1]}******" if user.pin.present?
          end
          column "Series Count", sortable: false do |user|
            user.series.count
          end
          column "Joined", sortable: "created_at" do |user|
            user.created_at
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :tvdb_id, hint: "TheTVDB Series ID"
      f.input :name
      f.input :imdb_id, hint: "IMDB ID (e.g., tt1234567)"
      f.input :last_synced_at, as: :datetime_picker
    end
    f.actions
  end
end
