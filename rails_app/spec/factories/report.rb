# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    # Replace with a valid value if REPORT_TYPES is defined
    report_type { 'repository_growth' }
    state { Report::STATE_QUEUED }

    trait :queued do
      state { Report::STATE_QUEUED }
    end

    trait :cancelled do
      state { Report::STATE_CANCELLED }
    end

    trait :processing do
      state { Report::STATE_PROCESSING }
    end

    trait :failed do
      state { Report::STATE_FAILED }
    end

    trait :successful do
      state { Report::STATE_SUCCESSFUL }
      generated_at { Time.current }
      duration { rand(10..300) }
      after(:build) do |report|
        report.attach_file(io: StringIO.new('{"example": "data"}'), content_type: 'application/json')
      end
    end
  end
end
