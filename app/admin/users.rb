ActiveAdmin.register User do
  permit_params :pin, :last_synced_at

  # Custom actions for user sync
  member_action :sync, method: :post do
    UserSyncIndividualJob.perform_later(resource.pin, force: true)
    redirect_to admin_user_path(resource), notice: "User sync started for #{resource.pin[0..1]}******"
  end

  batch_action :sync_users do |ids|
    User.where(id: ids).find_each do |user|
      UserSyncIndividualJob.perform_later(user.pin, force: true)
    end
    redirect_to admin_users_path, notice: "Sync started for #{ids.count} users"
  end

  action_item :sync_user, only: :show do
    link_to "Force Sync", sync_admin_user_path(resource), method: :post
  end

  filter :id
  filter :pin_eq, as: :string, label: "PIN"
  filter :last_synced_at
  filter :created_at
  filter :updated_at

  # Display masked PIN for security
  index do
    selectable_column
    id_column
    column "PIN" do |user|
      "#{user.pin[0..1]}******" if user.pin.present?
    end
    column :last_synced_at
    column "Series Count" do |user|
      user.user_series.count
    end
    column :created_at
    column :updated_at
    actions
  end

  sidebar "Actions", only: :show do
    link_to "Force Sync User", sync_admin_user_path(resource), method: :post,
            class: "btn btn-primary",
            data: { confirm: "Force sync for this user? This will bypass sync time limits." }
  end

  show do
    attributes_table_for(resource) do
      row :id
      row "PIN (Masked)" do |user|
        "#{user.pin[0..1]}******" if user.pin.present?
      end
      row :last_synced_at
      row "Series Count" do |user|
        user.user_series.count
      end
      row :created_at
      row :updated_at
    end

    panel "User Series" do
      # Handle sorting for user series
      sort_order = case params[:order]
      when "series.name_asc"
        "series.name ASC"
      when "series.name_desc"
        "series.name DESC"
      when "series.tvdb_id_asc"
        "series.tvdb_id ASC"
      when "series.tvdb_id_desc"
        "series.tvdb_id DESC"
      when "user_series.created_at_asc"
        "user_series.created_at ASC"
      when "user_series.created_at_desc"
        "user_series.created_at DESC"
      else
        "user_series.created_at DESC"
      end

      user_series_collection = resource.user_series.includes(:series).order(sort_order)
      paginated_collection(user_series_collection.page(params[:user_series_page]).per(10), param_name: "user_series_page", download_links: false) do
        table_for(collection, sortable: true, class: "index_table") do
          column "Series", sortable: "series.name" do |us|
            link_to us.series.name, admin_series_path(us.series) if us.series
          end
          column "TVDB ID", sortable: "series.tvdb_id" do |us|
            us.series&.tvdb_id
          end
          column "Episodes", sortable: false do |us|
            us.series&.episodes&.count || 0
          end
          column "Added", sortable: "user_series.created_at" do |us|
            us.created_at
          end
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :pin, hint: "TheTVDB PIN for this user"
      f.input :last_synced_at, as: :datetime_picker
    end
    f.actions
  end
end
