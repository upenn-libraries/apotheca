# frozen_string_literal: true

FactoryBot.define do
  factory :import do
    association :bulk_import
    import_data do
      {
        action: 'CREATE',
        human_readable_name: 'Marian Anderson; SSID: 18792434; filename: 10-14-1.tif',
        metadata: {
          title: [
            { value: 'Marian Anderson' }
          ]
        },
        assets: { arranged_filenames: 'front.tif; back.tif', storage: 'sceti_digitized', path: 'trade_card/original' }
      }
    end

    trait :queued do
      state { Import::STATE_QUEUED }
    end

    trait :cancelled do
      state { Import::STATE_CANCELLED }
    end

    trait :processing do
      state { Import::STATE_PROCESSING }
    end

    trait :failed do
      state { Import::STATE_FAILED }
      process_errors { Array.new(rand(1..10)) { Faker::Lorem.sentence } }
    end

    trait :successful do
      state { Import::STATE_SUCCESSFUL }
      duration { Faker::Number.between(from: 1, to: 3000) }
      resource_identifier { "ark:/12345/#{Faker::Number.number(digits: 8)}" }
    end

    trait :with_no_assets do
      import_data do
        {
          action: 'CREATE',
          human_readable_name: 'Marian Anderson; SSID: 18792434; filename: 10-14-1.tif',
          metadata: {
            title: [
              { value: 'Marian Anderson' }
            ]
          }
        }
      end
    end
  end
end
