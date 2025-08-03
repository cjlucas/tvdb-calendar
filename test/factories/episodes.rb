FactoryBot.define do
  factory :episode do
    series
    title { "Test Episode" }
    season_number { 1 }
    air_date { Date.current + 1.day }
    is_season_finale { false }

    # Sequence for unique episode numbers
    sequence :episode_number do |n|
      n
    end

    trait :upcoming do
      air_date { Date.current + 1.day }
    end

    trait :aired do
      air_date { Date.current - 1.day }
    end

    trait :today do
      air_date { Date.current }
    end

    trait :with_air_time do
      air_datetime_utc { Time.current + 1.day }
      runtime_minutes { 60 }
    end

    trait :season_finale do
      is_season_finale { true }
    end

    trait :with_runtime do |minutes|
      runtime_minutes { minutes }
    end
  end
end
