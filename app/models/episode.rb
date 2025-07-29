class Episode < ApplicationRecord
  belongs_to :series
  has_many :users, through: :series

  validates :title, presence: true
  validates :season_number, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :episode_number, presence: true, numericality: { greater_than: 0 }
  validates :air_date, presence: true
  validates :runtime_minutes, numericality: { greater_than: 0 }, allow_nil: true

  scope :upcoming, -> { where("air_date >= ?", Date.current) }
  scope :aired, -> { where("air_date < ?", Date.current) }
  scope :upcoming_with_time, -> { where("air_datetime_utc >= ?", Time.current.utc) }
  scope :aired_with_time, -> { where("air_datetime_utc < ?", Time.current.utc) }

  def episode_code
    "#{season_number.to_s.rjust(2, '0')}x#{episode_number.to_s.rjust(2, '0')}"
  end

  def full_title
    title_text = series.name
    title_text += " - Season Finale" if is_season_finale?
    title_text
  end

  def location_text
    "#{title} (#{episode_code})"
  end

  def air_time_in_timezone(target_timezone = "America/New_York")
    return nil unless air_datetime_utc.present?
    air_datetime_utc.in_time_zone(target_timezone)
  end

  def end_time_in_timezone(target_timezone = "America/New_York")
    return nil unless air_datetime_utc.present? && runtime_minutes.present?
    start_time = air_time_in_timezone(target_timezone)
    raw_end_time = start_time + runtime_minutes.minutes
    round_up_to_nearest_15_minutes(raw_end_time)
  end

  def has_specific_air_time?
    air_datetime_utc.present?
  end

  def runtime_duration
    return nil unless runtime_minutes.present?
    runtime_minutes.minutes
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "air_date", "air_datetime_utc", "air_time", "created_at", "episode_number", "id", "is_season_finale", "original_timezone", "runtime_minutes", "season_number", "series_id", "title", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "series", "users" ]
  end

  private

  def round_up_to_nearest_15_minutes(time)
    minutes = time.min
    remainder = minutes % 15
    return time if remainder == 0

    minutes_to_add = 15 - remainder
    time + minutes_to_add.minutes
  end
end
