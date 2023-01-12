# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_export do
    association :user, :admin
    solr_params { %w[first second third] }
    state { 'successful' }
  end
end

