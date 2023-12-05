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

    trait :with_faker_metadata do
      users = (0..5).map { Faker::Internet.email }
      human_readable_name { Faker::Book.title }
      descriptive_metadata do
        format_type = ['Book', 'Manuscript', 'Audio Recording', 'Video Recording', 'Ancient Utensil'].sample
        {
          title: [{ value: human_readable_name }],
          description: Faker::Lorem.paragraphs.map { |p| { value: p } },
          physical_location: [{ value: Faker::IDNumber.spanish_foreign_citizen_number }],
          collection: [{ value: "#{Faker::GreekPhilosophers.name} collection" }],
          date: [{ value: Faker::Date.backward.to_s }],
          physical_format: [{ value: format_type }],
          subject: (0..rand(1..5)).to_a.map { { value: Faker::Educator.subject } },
          identifier: [{ value: Faker::Code.isbn }],
          item_type: [{ value: format_type }],
          language: [{ value: 'English' }, { value: Faker::Nation.language }]
        }
      end
      structural_metadata do
        { viewing_hint: ItemChangeSet::StructuralMetadataChangeSet::VIEWING_HINTS.sample }
      end
      internal_notes { Faker::Lorem.sentences(number: 2) }
      unique_identifier { "ark:/#{Faker::Number.number(digits: 8)}/random" }
      published { [true, false].sample }
      created_by { users.sample }
      updated_by { users.sample }
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
        asset { persist(:asset_resource, :with_preservation_file, :with_metadata) }
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
        asset1 { persist(:asset_resource, :with_preservation_file, :with_access_copy, :with_metadata) }
        asset2 do
          persist(:asset_resource, :with_preservation_file, :with_access_copy,
                  original_filename: 'back.tif', preservation_file: 'back.tif')
        end
      end

      asset_ids { [asset1.id, asset2.id] }
      thumbnail_asset_id { asset1.id }

      structural_metadata { { arranged_asset_ids: [asset1.id, asset2.id] } }
    end

    trait :with_bibnumber do
      descriptive_metadata do
        {
          bibnumber: [{ value: 'sample-bib' }],
          abstract: [],
          date: [{ value: '1900' }, { value: '1475' }],
          collection: [{ value: 'Fake Collection' }]
        }
      end
    end
  end
end
