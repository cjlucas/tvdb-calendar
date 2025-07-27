class UserSeries < ApplicationRecord
  belongs_to :user
  belongs_to :series

  validates :user_id, uniqueness: { scope: :series_id }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "series_id", "updated_at", "user_id"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["series", "user"]
  end
end
