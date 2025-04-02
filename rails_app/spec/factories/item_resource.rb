# frozen_string_literal: true

# Factory for ItemResource.
#
# Use `.build` to build object and use `.persist` to persist via Valkyrie persister.
#
# For the Valkyrie factories, we took a lot of inspiration from Figgy's resource factories.
# Example: https://github.com/pulibrary/figgy/blob/main/spec/factories/scanned_resource.rb
FactoryBot.define do
  factory :item_resource do
    human_readable_name { 'New Item' }
    descriptive_metadata do
      { title: [{ value: 'New Item' }] }
    end
    structural_metadata do
      { viewing_hint: 'paged' }
    end
    internal_notes { ['One note', 'Another Note'] }
    unique_identifier { "#{Ezid::Client.config.default_shoulder}random" }
    created_by { 'admin@library.upenn.edu' }
    updated_by { 'admin@library.upenn.edu' }

    trait :migrated do
      first_created_at { 2.years.ago }
    end

    trait :with_faker_metadata do
      users = (0..5).map { Faker::Internet.email }
      human_readable_name { Faker::Book.title }
      descriptive_metadata do
        format_type = ['Book', 'Manuscript', 'Audio Recording', 'Video Recording', 'Ancient Utensil'].sample
        {
          title: [{ value: human_readable_name }],
          description: Faker::Lorem.paragraphs.map { |p| { value: p } },
          physical_location: [{ value: Faker::IdNumber.spanish_foreign_citizen_number }],
          collection: [{ value: "#{Faker::GreekPhilosophers.name} collection" }],
          date: [{ value: Faker::Date.backward.to_s }],
          physical_format: [{ value: format_type }],
          subject: (0..rand(1..5)).to_a.map { { value: Faker::Educator.subject } },
          identifier: [{ value: Faker::Code.isbn }],
          item_type: [{ value: format_type, uri: 'https://test-uri.com/uri' }],
          language: [{ value: 'English' }, { value: Faker::Nation.language }]
        }
      end
      structural_metadata do
        { viewing_hint: ItemChangeSet::StructuralMetadataChangeSet::VIEWING_HINTS.sample }
      end
      internal_notes { Faker::Lorem.sentences(number: 2) }
      unique_identifier { "ark:/#{Faker::Number.number(digits: 8)}/random" }
      created_by { users.sample }
      updated_by { users.sample }
    end

    trait :printed do
      ocr_type { 'printed' }
    end

    trait :published do
      published { true }
      first_published_at { DateTime.current }
      last_published_at { DateTime.current }
    end

    trait :with_derivatives do
      transient do
        iiif_manifest { true }
        pdf { true }
      end

      after(:create) do |item, evaluator|
        derivative_service = DerivativeService::Item::Derivatives.new(ItemChangeSet.new(item))

        %w[iiif_manifest pdf].each do |type|
          next unless evaluator.send(type) # Check if derivative was requested.

          derivative = derivative_service.send(type)

          next if derivative.nil? # Return early if no derivative could be generated.

          derivative_storage = Valkyrie::StorageAdapter.find(:derivatives)

          file = derivative_storage.upload(file: derivative, resource: item, original_filename: type)

          item.derivatives << DerivativeResource.new(file_id: file.id, mime_type: derivative.mime_type,
                                                     size: derivative.size, type: type, generated_at: DateTime.current)
        end
      end
    end

    # Item with one Asset containing only the required attributes.
    trait :with_asset do
      transient do
        asset { persist(:asset_resource) }
      end

      asset_ids { [asset.id] }
      thumbnail_asset_id { asset.id }
    end

    # Item with one Asset containing metadata and a preservation file.
    trait :with_full_asset do
      with_asset

      transient do
        asset { persist(:asset_resource, :with_image_file, :with_metadata) }
      end
    end

    # Item with two Assets, one arranged, one not arranged.
    trait :with_assets_some_arranged do
      transient do
        asset1 { persist(:asset_resource, original_filename: 'page1') }
        asset2 { persist(:asset_resource, original_filename: 'page2') }
      end

      asset_ids { [asset1.id, asset2.id] }
      thumbnail_asset_id { asset1.id }

      structural_metadata { { arranged_asset_ids: [asset1.id] } }
    end

    # Item with two Assets, all arranged.
    trait :with_assets_all_arranged do
      with_assets_some_arranged

      structural_metadata { { arranged_asset_ids: [asset1.id, asset2.id] } }
    end

    # Item with two arranged Asset containing metadata and a preservation file.
    trait :with_full_assets_all_arranged do
      transient do
        asset1 { persist(:asset_resource, :with_image_file, :with_derivatives, :with_metadata) }
        asset2 do
          persist(:asset_resource, :with_image_file, :with_derivatives,
                  original_filename: 'back.tif', preservation_file: 'trade_card/original/back.tif')
        end
      end

      asset_ids { [asset1.id, asset2.id] }
      thumbnail_asset_id { asset1.id }

      structural_metadata { { arranged_asset_ids: [asset1.id, asset2.id] } }
    end

    trait :with_bibnumber do
      descriptive_metadata do
        {
          bibnumber: [{ value: MMSIDValidator::EXAMPLE_VALID_MMS_ID }],
          abstract: [],
          date: [{ value: '1900' }, { value: '1475' }],
          collection: [{ value: 'Fake Collection' }],
          language: [{ value: 'English' }]
        }
      end
    end
  end
end
