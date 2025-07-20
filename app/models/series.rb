class Series < ApplicationRecord
  belongs_to :user
  has_many :episodes, dependent: :destroy

  validates :tvdb_id, presence: true, uniqueness: { scope: :user_id }
  validates :name, presence: true

  def imdb_url
    return nil unless imdb_id.present?
    "https://www.imdb.com/title/#{imdb_id}/"
  end
end
