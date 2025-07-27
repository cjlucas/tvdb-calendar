ActiveAdmin.register Episode do
  menu priority: 4
  permit_params :series_id, :title, :season_number, :episode_number, :air_date, :is_season_finale, :air_time, :runtime_minutes, :original_timezone, :air_datetime_utc

  index do
    selectable_column
    id_column
    column :series do |episode|
      link_to episode.series.name, admin_series_path(episode.series)
    end
    column :title
    column :episode_code
    column :air_date
    column :air_datetime_utc
    column :runtime_minutes
    column :is_season_finale do |episode|
      status_tag(episode.is_season_finale ? "Yes" : "No", class: episode.is_season_finale ? "yes" : "no")
    end
    column :created_at
    actions
  end

  filter :series, as: :select, collection: -> { Series.order(:name) }
  filter :title
  filter :season_number
  filter :episode_number
  filter :air_date
  filter :is_season_finale
  filter :created_at

  scope :upcoming
  scope :aired
  scope :upcoming_with_time
  scope :aired_with_time

  show do
    attributes_table do
      row :id
      row :series do |episode|
        link_to episode.series.name, admin_series_path(episode.series)
      end
      row :title
      row :season_number
      row :episode_number
      row :episode_code
      row :air_date
      row :air_time
      row :air_datetime_utc
      row :original_timezone
      row :runtime_minutes do |episode|
        "#{episode.runtime_minutes} minutes" if episode.runtime_minutes
      end
      row :is_season_finale do |episode|
        status_tag(episode.is_season_finale ? "Yes" : "No", class: episode.is_season_finale ? "yes" : "no")
      end
      row :created_at
      row :updated_at
      row :full_title
      row :location_text
      row :has_specific_air_time? do |episode|
        status_tag(episode.has_specific_air_time? ? "Yes" : "No", class: episode.has_specific_air_time? ? "yes" : "no")
      end
    end
  end
end
