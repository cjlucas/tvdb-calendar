class User < ApplicationRecord
  validates :pin, presence: true, uniqueness: true

  has_many :user_series, dependent: :destroy
  has_many :series, through: :user_series
  has_many :episodes, through: :series

  def needs_sync?
    last_synced_at.nil? || last_synced_at < 1.hour.ago
  end

  def mark_as_synced!
    update!(last_synced_at: Time.current)
  end
end
