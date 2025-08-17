FactoryBot.define do
  factory :series do
    tvdb_id { rand(100000..999999) }
    name { "Test Series" }
    imdb_id { "tt1234567" }

    trait :without_imdb_id do
      imdb_id { nil }
    end

    trait :needs_sync do
      last_synced_at { nil }
    end

    trait :recently_synced do
      last_synced_at { 30.minutes.ago }
    end

    trait :stale_sync do
      last_synced_at { 2.hours.ago }
    end

    trait :with_name do |name_value|
      name { name_value }
    end
  end
end
