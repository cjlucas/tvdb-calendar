class Episode < ApplicationRecord
  belongs_to :series
  has_one :user, through: :series

  validates :title, presence: true
  validates :season_number, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :episode_number, presence: true, numericality: { greater_than: 0 }
  validates :air_date, presence: true

  scope :upcoming, -> { where('air_date >= ?', Date.current) }
  scope :aired, -> { where('air_date < ?', Date.current) }

  def episode_code
    "S#{season_number.to_s.rjust(2, '0')}E#{episode_number.to_s.rjust(2, '0')}"
  end

  def full_title
    title_text = series.name
    title_text += " - Season Finale" if is_season_finale?
    title_text
  end

  def location_text
    "#{title} - (#{episode_code})"
  end
end
