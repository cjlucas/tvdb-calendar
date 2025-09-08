FactoryBot.define do
  factory :episode do
    series
    title { "Test Episode" }
    season_number { 1 }
    air_date { Date.current + 1.day }
    is_season_finale { false }
    overview { nil }

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

    trait :with_overview do
      overview { "This is a detailed episode overview that describes the plot and characters." }
    end

    trait :with_long_overview do
      overview do
        "This is a very long episode overview that contains multiple sentences and detailed plot information. " \
        "It describes the characters, their motivations, and the events that unfold during the episode. " \
        "The overview might include information about character development, plot twists, and important story elements."
      end
    end
  end
end
