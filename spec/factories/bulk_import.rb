# frozen_string_literal: true

FactoryBot.define do
  factory :bulk_import do
    association :created_by, factory: [:user, :admin]
    original_filename { Faker::File.file_name(ext: 'csv', directory_separator: '') }
    csv_rows do
      csv_data = Rails.root.join('spec/fixtures/imports/bulk_import_data.csv').read
      StructuredCSV.parse(csv_data)
    end
  end
end
