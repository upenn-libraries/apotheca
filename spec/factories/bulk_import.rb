# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import do
    association :created_by, factory: [:user, :admin]
    original_filename { Faker::File.file_name(ext: 'csv', directory_separator: '') }
  end
end
