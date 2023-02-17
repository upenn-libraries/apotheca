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
  end
end
