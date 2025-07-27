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

  def needs_sync?
    last_synced_at.nil? || last_synced_at < 12.hours.ago
  end

  def mark_as_synced!
    update!(last_synced_at: Time.current)
  end

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "imdb_id", "last_synced_at", "name", "tvdb_id", "updated_at"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["episodes", "users", "user_series"]
  end
end
