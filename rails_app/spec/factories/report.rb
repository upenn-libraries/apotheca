# frozen_string_literal: true

FactoryBot.define do
  factory :report do
    # Replace with a valid value if REPORT_TYPES is defined
    report_type { 'repository_growth' }
    # Should the default state be queued? BulkExport is SUCCESS
    state { Report::STATE_QUEUED }
    duration { rand(10..300) }

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
      # TODO: maybe we need process errors like bulk export?
      # process_errors { ['This is an error message!'] }
    end

    trait :successful do
      state { Report::STATE_SUCCESSFUL }
      generated_at { Time.current }
      after(:build) do |report|
        report.file.attach(
          io: StringIO.new('{"example": "data"}'),
          filename: 'report.json',
          # TODO: do some research on whether the activestorage blob can return mime type
          content_type: 'application/json'
        )
      end
    end
  end
end
