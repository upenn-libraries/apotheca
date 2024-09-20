# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_export do
    association :created_by, factory: %i[user admin]
    search_params { { search: { all: 'New' } } }
    state { BulkExport::STATE_SUCCESSFUL }

    trait :queued do
      state { BulkExport::STATE_QUEUED }
    end

    trait :cancelled do
      state { BulkExport::STATE_CANCELLED }
    end

    trait :processing do
      state { BulkExport::STATE_PROCESSING }
    end

    trait :failed do
      state { BulkExport::STATE_FAILED }
      process_errors { ['This is an error message!'] }
    end

    trait :successful do
      state { BulkExport::STATE_SUCCESSFUL }
      records_count { [0...12].sample }
    end
  end
end
