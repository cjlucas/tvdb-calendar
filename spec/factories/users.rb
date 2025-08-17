FactoryBot.define do
  factory :user do
    pin { "test_#{rand(100000..999999)}" }
    uuid { SecureRandom.uuid_v7 }

    trait :needs_sync do
      last_synced_at { nil }
    end

    trait :recently_synced do
      last_synced_at { 30.minutes.ago }
    end

    trait :stale_sync do
      last_synced_at { 2.hours.ago }
    end

    trait :with_pin do |pin_value|
      pin { pin_value }
    end
  end
end
