ActiveAdmin.register Episode do
  permit_params :series_id, :title, :season_number, :episode_number, :air_date, :is_season_finale, :air_time, :runtime_minutes, :original_timezone, :air_datetime_utc

  filter :id
  filter :series
  filter :title
  filter :season_number
  filter :episode_number
  filter :air_date
  filter :is_season_finale
  filter :air_datetime_utc
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :series do |episode|
      link_to episode.series.name, admin_series_path(episode.series)
    end
    column "Episode" do |episode|
      "S#{episode.season_number}E#{episode.episode_number}"
    end
    column :title
    column :air_date
    column :air_datetime_utc
    column :runtime_minutes
    column :is_season_finale
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :series do |episode|
        link_to episode.series.name, admin_series_path(episode.series)
      end
      row "Episode Code" do |episode|
        episode.episode_code
      end
      row :title
      row :season_number
      row :episode_number
      row :air_date
      row :air_datetime_utc
      row :air_time
      row :runtime_minutes do |episode|
        "#{episode.runtime_minutes} minutes" if episode.runtime_minutes
      end
      row :original_timezone
      row :is_season_finale
      row :created_at
      row :updated_at
    end

    panel "Air Times in Different Timezones" do
      if resource.has_specific_air_time?
        table do
          tr do
            th "Timezone"
            th "Air Time"
            th "End Time"
          end
          [ "America/New_York", "America/Chicago", "America/Denver", "America/Los_Angeles", "UTC" ].each do |tz|
            tr do
              td tz
              td resource.air_time_in_timezone(tz)&.strftime("%Y-%m-%d %I:%M %p %Z")
              td resource.end_time_in_timezone(tz)&.strftime("%Y-%m-%d %I:%M %p %Z")
            end
          end
        end
      else
        div "No specific air time available"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :series, collection: Series.order(:name)
      f.input :title
      f.input :season_number
      f.input :episode_number
      f.input :air_date, as: :date_picker
      f.input :air_datetime_utc, as: :datetime_picker, hint: "Air time in UTC"
      f.input :air_time, as: :datetime_picker, hint: "Original air time"
      f.input :runtime_minutes, hint: "Episode runtime in minutes"
      f.input :original_timezone, hint: "Original timezone (e.g., America/New_York)"
      f.input :is_season_finale
    end
    f.actions
  end
end
