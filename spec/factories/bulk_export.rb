# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_export do
    association :user, :admin
    solr_params { { search: { all: 'New' } } }
    state { BulkExport::STATE_SUCCESSFUL }
  end

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
  end
end

