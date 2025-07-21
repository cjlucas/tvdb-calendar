class Series < ApplicationRecord
  has_many :user_series, dependent: :destroy
  has_many :users, through: :user_series
  has_many :episodes, dependent: :destroy

  validates :tvdb_id, presence: true, uniqueness: true
  validates :name, presence: true

  def imdb_url
    return nil unless imdb_id.present?
    "https://www.imdb.com/title/#{imdb_id}/"
  end
end
