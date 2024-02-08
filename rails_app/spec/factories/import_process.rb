# frozen_string_literal: true

# Factory for ImportService::Process.
#
# This factory is for a non-ActiveModel object. Use `.build` or `.create` to instantiate an object.
FactoryBot.define do
  factory :import_process, class: 'ImportService::Process' do
    imported_by { 'importer@example.com' }

    trait :create do
      action { ImportService::Process::CREATE }
      human_readable_name { 'Trade card; J. Rosenblatt & Co.' }
      structural { { viewing_direction: 'left-to-right', viewing_hint: 'individuals' } }
      assets { { arranged_filenames: 'front.tif; back.tif', storage: 'sceti_digitized', path: 'trade_card/original' } }
      metadata do
        {
          'collection' => [
            { value: 'Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)' }
          ],
          'physical_location' => [{ value: 'Arc.MS.56' }],
          'item_type' => [{ value: 'Trade cards' }],
          'language' => [{ value: 'English' }],
          'date' => [{ value: 'undated' }],
          'name' => [{ value: 'J. Rosenblatt & Co.' }],
          'geographic_subject' => [
            { value: 'Baltimore, Maryland, United States' },
            { value: 'Maryland, United States' }
          ],
          'description' => [
            { value: 'J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties' },
            { value: '32 South Howard Street, Baltimore, MD' }
          ],
          'rights' => [{ value: 'No Copyright', uri: 'http://rightsstatements.org/page/NoC-US/1.0/?' }],
          'subject' => [
            { value: 'House furnishings' }, { value: 'Jewish merchants' }, { value: 'Trade cards (advertising)' }
          ],
          'title' => [{ value: 'Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;' }]
        }
      end
    end

    trait :update do
      action { ImportService::Process::UPDATE }
    end

    trait :migrate do
      action { ImportService::Process::MIGRATE }
    end

    trait :publish do
      publish { 'true' }
    end

    trait :with_asset_metadata do
      assets do
        {
          arranged: [
            { filename: 'front.tif', label: 'Front', transcription: ['Importers'] },
            { filename: 'back.tif',  label: 'Back', annotation: ['mostly blank'] }
          ],
          storage: 'sceti_digitized',
          path: 'trade_card/original'
        }
      end
    end

    trait :invalid do
      action { 'invalid' }
    end

    skip_create
    initialize_with { ImportService::Process.build(**attributes) }
  end
end
