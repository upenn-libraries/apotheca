# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_export do
    association :user, :admin
    solr_params { { search: { all: 'Crunchy' } } }
    state { BulkExport::STATE_SUCCESSFUL }
  end
end

