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
      structural { { viewing_direction: 'left-to-right', viewing_hint: 'individual' } }
      assets { { arranged_filenames: 'front.tif; back.tif', storage: 'sceti_digitized', path: 'trade_card/original' } }
      metadata do
        {
          'collection' => ['Arnold and Deanne Kaplan Collection of Early American Judaica (University of Pennsylvania)'],
          'physical_location' => ['Arc.MS.56'],
          'item_type' => [{ label: 'Trade cards' }],
          'language' => [{ label: 'English' }],
          'date' => ['undated'],
          'name' => [{ label: 'J. Rosenblatt & Co.' }],
          'geographic_subject' => [
            { label: 'Baltimore, Maryland, United States' },
            { label: 'Maryland, United States' }
          ],
          'description' => [
            'J. Rosenblatt & Co.: Importers: Earthenware, China, Majolica, Novelties',
            '32 South Howard Street, Baltimore, MD'
          ],
          'rights' => [{ label: 'No Copyright', uri: 'http://rightsstatements.org/page/NoC-US/1.0/?' }],
          'subject' => [
            { label: 'House furnishings' }, { label: 'Jewish merchants' }, { label: 'Trade cards (advertising)' }
          ],
          'title' => ['Trade card; J. Rosenblatt & Co.; Baltimore, Maryland, United States; undated;']
        }
      end
    end

    trait :update do
      action { ImportService::Process::UPDATE }
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
