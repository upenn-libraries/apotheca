# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import do
    association :created_by, factory: [:user, :admin]
    trait :with_original_filename do
      original_filename { Faker::File.file_name(ext: 'csv') }
    end
  end
end
