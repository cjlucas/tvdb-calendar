class User < ApplicationRecord
  validates :pin, presence: true, uniqueness: true
  validate :pin_must_be_valid_with_tvdb, on: :create

  has_many :user_series, dependent: :destroy
  has_many :series, through: :user_series
  has_many :episodes, through: :series

  def needs_sync?
    last_synced_at.nil? || last_synced_at < 1.hour.ago
  end

  def mark_as_synced!
    update!(last_synced_at: Time.current)
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "id", "last_synced_at", "pin", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "episodes", "series", "user_series" ]
  end

  private

  def pin_must_be_valid_with_tvdb
    return if pin.blank?
    # Skip validation in test environment if SKIP_PIN_VALIDATION is set
    return if Rails.env.test? && ENV["SKIP_PIN_VALIDATION"] == "true"

    client = tvdb_client
    client.authenticate(pin)
  rescue InvalidPinError
    errors.add(:pin, "is invalid")
  rescue => e
    Rails.logger.error "TVDB API error during PIN validation: #{e.message}"
    errors.add(:pin, "could not be validated - please try again")
  end

  def tvdb_client
    TvdbClient.new
  end
end
