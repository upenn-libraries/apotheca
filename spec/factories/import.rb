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
            'Marian Anderson'
          ]
        }
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
    end

    trait :successful do
      state { Import::STATE_SUCCESSFUL }
      duration { Faker::Number.between(from: 1, to: 300) }
    end
  end
end
