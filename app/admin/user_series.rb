ActiveAdmin.register UserSeries do
  menu priority: 2
  permit_params :user_id, :series_id

  index do
    selectable_column
    id_column
    column :user do |user_series|
      link_to user_series.user.pin, admin_user_path(user_series.user)
    end
    column :series do |user_series|
      link_to user_series.series.name, admin_series_path(user_series.series)
    end
    column :created_at
    actions
  end

  filter :user_id_eq, as: :string, label: "User ID"
  filter :user_pin_eq, as: :string, label: "User PIN"
  filter :series, as: :select, collection: -> { Series.order(:name) }
  filter :created_at

  show do
    attributes_table do
      row :id
      row :user do |user_series|
        link_to user_series.user.pin, admin_user_path(user_series.user)
      end
      row :series do |user_series|
        link_to user_series.series.name, admin_series_path(user_series.series)
      end
      row :created_at
      row :updated_at
    end
  end
end
