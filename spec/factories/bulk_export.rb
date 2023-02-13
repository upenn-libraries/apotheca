# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_export do
    association :user, :admin
    solr_params { { search: { all: 'New' } } }
    state { BulkExport::STATE_SUCCESSFUL }
  end

  trait :with_processing_state do
    state { BulkExport::STATE_PROCESSING }
  end

  trait :queued do
    state { BulkExport::STATE_QUEUED }
  end
end

