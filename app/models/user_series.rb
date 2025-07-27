class UserSeries < ApplicationRecord
  belongs_to :user
  belongs_to :series

  validates :user_id, uniqueness: { scope: :series_id }

  def self.ransackable_attributes(auth_object = nil)
    ["created_at", "id", "series_id", "updated_at", "user_id", "user_pin_eq"]
  end

  def self.ransackable_associations(auth_object = nil)
    ["series", "user"]
  end

  ransacker :user_pin_eq,
    formatter: proc { |v| v },
    splat_params: true do |parent|
    parent.table.join(User.arel_table, Arel::Nodes::InnerJoin)
          .on(parent.table[:user_id].eq(User.arel_table[:id]))
          .project(User.arel_table[:pin])
  end
end
