class User < ApplicationRecord
  validates :pin, presence: true, uniqueness: true
  validates :uuid, presence: true, uniqueness: true

  before_create :generate_uuid

  has_many :user_series, dependent: :destroy
  has_many :series, through: :user_series
  has_many :episodes, through: :series

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "id_value", "last_synced_at", "pin", "updated_at", "uuid" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "episodes", "series", "user_series" ]
  end

  def needs_sync?
    last_synced_at.nil? || last_synced_at < 1.hour.ago
  end

  def mark_as_synced!
    update!(last_synced_at: Time.current)
  end

  def regenerate_uuid!
    update!(uuid: SecureRandom.uuid_v7)
  end

  private

  def generate_uuid
    self.uuid ||= SecureRandom.uuid_v7
  end
end
